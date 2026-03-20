const std = @import("std");
const h5e = @import("browser/parser/html5ever.zig");

const Allocator = std.mem.Allocator;
const gpa = std.heap.c_allocator;
const empty_bytes = [_]u8{0};

const CreateElementCallback = *const fn (ctx: *anyopaque, data: *anyopaque, h5e.QualName, h5e.AttributeIterator) callconv(.c) ?*anyopaque;
const ElemNameCallback = *const fn (node_ref: *anyopaque) callconv(.c) *anyopaque;
const AppendCallback = *const fn (ctx: *anyopaque, parent_ref: *anyopaque, h5e.NodeOrText) callconv(.c) void;
const ParseErrorCallback = *const fn (ctx: *anyopaque, h5e.StringSlice) callconv(.c) void;
const PopCallback = *const fn (ctx: *anyopaque, node_ref: *anyopaque) callconv(.c) void;
const CreateCommentCallback = *const fn (ctx: *anyopaque, h5e.StringSlice) callconv(.c) ?*anyopaque;
const CreateProcessingInstructionCallback = *const fn (ctx: *anyopaque, h5e.StringSlice, h5e.StringSlice) callconv(.c) ?*anyopaque;
const AppendDoctypeToDocumentCallback = *const fn (ctx: *anyopaque, h5e.StringSlice, h5e.StringSlice, h5e.StringSlice) callconv(.c) void;
const AddAttrsIfMissingCallback = *const fn (ctx: *anyopaque, target_ref: *anyopaque, h5e.AttributeIterator) callconv(.c) void;
const GetTemplateContentsCallback = *const fn (ctx: *anyopaque, target_ref: *anyopaque) callconv(.c) ?*anyopaque;
const RemoveFromParentCallback = *const fn (ctx: *anyopaque, target_ref: *anyopaque) callconv(.c) void;
const ReparentChildrenCallback = *const fn (ctx: *anyopaque, node_ref: *anyopaque, new_parent_ref: *anyopaque) callconv(.c) void;
const AppendBeforeSiblingCallback = *const fn (ctx: *anyopaque, sibling_ref: *anyopaque, h5e.NodeOrText) callconv(.c) void;
const AppendBasedOnParentNodeCallback = *const fn (ctx: *anyopaque, element_ref: *anyopaque, prev_element_ref: *anyopaque, h5e.NodeOrText) callconv(.c) void;

const CallbackSet = struct {
    ctx: *anyopaque,
    create_element: CreateElementCallback,
    elem_name: ElemNameCallback,
    append: AppendCallback,
    parse_error: ParseErrorCallback,
    pop: PopCallback,
    create_comment: CreateCommentCallback,
    create_processing_instruction: CreateProcessingInstructionCallback,
    append_doctype_to_document: AppendDoctypeToDocumentCallback,
    add_attrs_if_missing: AddAttrsIfMissingCallback,
    get_template_contents: GetTemplateContentsCallback,
    remove_from_parent: RemoveFromParentCallback,
    reparent_children: ReparentChildrenCallback,
    append_before_sibling: AppendBeforeSiblingCallback,
    append_based_on_parent_node: AppendBasedOnParentNodeCallback,
};

const StackEntry = struct {
    node_ref: *anyopaque,
    tag_name: []const u8,
};

const AttrIterCtx = struct {
    attrs: []h5e.Attribute,
    index: usize = 0,
};

const ElementData = struct {
    tag_name: []const u8,
};

const ParserOptions = struct {
    xml_mode: bool = false,
    fragment_mode: bool = false,
};

const StreamingParser = struct {
    doc: *anyopaque,
    callbacks: CallbackSet,
    xml_mode: bool,
    buffer: std.ArrayList(u8) = .empty,

    fn deinit(self: *StreamingParser) void {
        self.buffer.deinit(gpa);
        gpa.destroy(self);
    }
};

fn toStringSlice(bytes: []const u8) h5e.StringSlice {
    return .{
        .ptr = if (bytes.len == 0) empty_bytes[0..].ptr else bytes.ptr,
        .len = bytes.len,
    };
}

fn noneStringSlice() h5e.Nullable(h5e.StringSlice) {
    return h5e.Nullable(h5e.StringSlice).none();
}

fn makeQualName(raw_name: []const u8, ns: []const u8) h5e.QualName {
    if (std.mem.indexOfScalar(u8, raw_name, ':')) |colon| {
        const prefix = raw_name[0..colon];
        const local = raw_name[colon + 1 ..];
        return .{
            .prefix = .{ .tag = 1, .value = toStringSlice(prefix) },
            .ns = toStringSlice(ns),
            .local = toStringSlice(local),
        };
    }
    return .{
        .prefix = noneStringSlice(),
        .ns = toStringSlice(ns),
        .local = toStringSlice(raw_name),
    };
}

fn makeNodeOrTextNode(node_ref: *anyopaque) h5e.NodeOrText {
    return .{
        .tag = 0,
        .node = node_ref,
        .text = toStringSlice(""),
    };
}

fn makeNodeOrTextText(text: []const u8) h5e.NodeOrText {
    return .{
        .tag = 1,
        .node = @ptrFromInt(1),
        .text = toStringSlice(text),
    };
}

fn skipWhitespace(input: []const u8, i_ptr: *usize) void {
    while (i_ptr.* < input.len and std.ascii.isWhitespace(input[i_ptr.*])) : (i_ptr.* += 1) {}
}

fn findTagEnd(input: []const u8, start: usize) usize {
    var i = start;
    var quote: ?u8 = null;
    while (i < input.len) : (i += 1) {
        const c = input[i];
        if (quote) |q| {
            if (c == q) quote = null;
            continue;
        }
        if (c == '"' or c == '\'') {
            quote = c;
            continue;
        }
        if (c == '>') return i;
    }
    return input.len;
}

fn parseTagName(input: []const u8, i_ptr: *usize) []const u8 {
    const start = i_ptr.*;
    while (i_ptr.* < input.len) : (i_ptr.* += 1) {
        const c = input[i_ptr.*];
        if (std.ascii.isWhitespace(c) or c == '>' or c == '/') break;
    }
    return input[start..i_ptr.*];
}

fn parseAttributeValue(input: []const u8, i_ptr: *usize) []const u8 {
    if (i_ptr.* >= input.len) return "";
    const start_char = input[i_ptr.*];
    if (start_char == '"' or start_char == '\'') {
        const quote = start_char;
        i_ptr.* += 1;
        const start = i_ptr.*;
        while (i_ptr.* < input.len and input[i_ptr.*] != quote) : (i_ptr.* += 1) {}
        const value = input[start..@min(i_ptr.*, input.len)];
        if (i_ptr.* < input.len) i_ptr.* += 1;
        return value;
    }
    const start = i_ptr.*;
    while (i_ptr.* < input.len) : (i_ptr.* += 1) {
        const c = input[i_ptr.*];
        if (std.ascii.isWhitespace(c) or c == '>' or c == '/') break;
    }
    return input[start..i_ptr.*];
}

fn parseAttributes(allocator: Allocator, input: []const u8, i_ptr: *usize) !std.ArrayList(h5e.Attribute) {
    var attrs: std.ArrayList(h5e.Attribute) = .empty;
    while (i_ptr.* < input.len) {
        skipWhitespace(input, i_ptr);
        if (i_ptr.* >= input.len) break;
        if (input[i_ptr.*] == '/' or input[i_ptr.*] == '>') break;

        const name_start = i_ptr.*;
        while (i_ptr.* < input.len) : (i_ptr.* += 1) {
            const c = input[i_ptr.*];
            if (std.ascii.isWhitespace(c) or c == '=' or c == '/' or c == '>') break;
        }
        const raw_name = input[name_start..i_ptr.*];
        skipWhitespace(input, i_ptr);

        var value: []const u8 = "";
        if (i_ptr.* < input.len and input[i_ptr.*] == '=') {
            i_ptr.* += 1;
            skipWhitespace(input, i_ptr);
            value = parseAttributeValue(input, i_ptr);
        }

        try attrs.append(allocator, .{
            .name = makeQualName(raw_name, ""),
            .value = toStringSlice(value),
        });
    }
    return attrs;
}

fn isVoidHtmlElement(name: []const u8) bool {
    const names = [_][]const u8{
        "area", "base",  "br",    "col",   "embed", "hr",
        "img",  "input", "link",  "meta",  "param", "source",
        "track", "wbr",
    };
    for (names) |void_name| {
        if (std.ascii.eqlIgnoreCase(name, void_name)) return true;
    }
    return false;
}

fn appendText(callbacks: CallbackSet, parent_ref: *anyopaque, text: []const u8) void {
    if (text.len == 0) return;
    callbacks.append(callbacks.ctx, parent_ref, makeNodeOrTextText(text));
}

fn appendElement(callbacks: CallbackSet, _parent_ref: *anyopaque, tag_name: []const u8, attrs: []h5e.Attribute, ns: []const u8) !?*anyopaque {
    _ = _parent_ref;
    var attr_iter_ctx = AttrIterCtx{ .attrs = attrs };
    const data = try gpa.create(ElementData);
    data.* = .{ .tag_name = tag_name };
    return callbacks.create_element(
        callbacks.ctx,
        data,
        makeQualName(tag_name, ns),
        .{ .iter = &attr_iter_ctx },
    );
}

fn popUntil(stack: *std.ArrayList(StackEntry), callbacks: CallbackSet, tag_name: []const u8, xml_mode: bool) void {
    if (stack.items.len <= 1) return;

    var match_index: ?usize = null;
    var i = stack.items.len;
    while (i > 1) {
        i -= 1;
        const entry = stack.items[i];
        const matches = if (xml_mode)
            std.mem.eql(u8, entry.tag_name, tag_name)
        else
            std.ascii.eqlIgnoreCase(entry.tag_name, tag_name);
        if (matches) {
            match_index = i;
            break;
        }
    }

    const end_index = match_index orelse return;
    while (stack.items.len > end_index) {
        const entry = stack.pop().?;
        callbacks.pop(callbacks.ctx, entry.node_ref);
    }
}

fn parseDocumentLike(input: []const u8, doc: *anyopaque, callbacks: CallbackSet, options: ParserOptions) !void {
    var stack: std.ArrayList(StackEntry) = .empty;
    defer stack.deinit(gpa);
    try stack.append(gpa, .{ .node_ref = doc, .tag_name = "#document" });

    var i: usize = 0;
    while (i < input.len) {
        if (input[i] != '<') {
            const next = std.mem.indexOfScalarPos(u8, input, i, '<') orelse input.len;
            appendText(callbacks, stack.items[stack.items.len - 1].node_ref, input[i..next]);
            i = next;
            continue;
        }

        if (std.mem.startsWith(u8, input[i..], "<!--")) {
            const content_start = i + 4;
            const end = std.mem.indexOfPos(u8, input, content_start, "-->") orelse input.len;
            const comment_text = input[content_start..end];
            if (callbacks.create_comment(callbacks.ctx, toStringSlice(comment_text))) |comment_ref| {
                callbacks.append(callbacks.ctx, stack.items[stack.items.len - 1].node_ref, makeNodeOrTextNode(comment_ref));
            }
            i = if (end < input.len) end + 3 else input.len;
            continue;
        }

        if (std.mem.startsWith(u8, input[i..], "<!DOCTYPE") or std.mem.startsWith(u8, input[i..], "<!doctype")) {
            const end = findTagEnd(input, i + 2);
            const body = std.mem.trim(u8, input[i + 2 .. end], &std.ascii.whitespace);
            var parts = std.mem.tokenizeScalar(u8, body, ' ');
            _ = parts.next(); // DOCTYPE
            const name = parts.next() orelse "html";
            callbacks.append_doctype_to_document(callbacks.ctx, toStringSlice(name), toStringSlice(""), toStringSlice(""));
            i = if (end < input.len) end + 1 else input.len;
            continue;
        }

        if (std.mem.startsWith(u8, input[i..], "<?")) {
            const content_start = i + 2;
            const end = std.mem.indexOfPos(u8, input, content_start, "?>") orelse input.len;
            const body = std.mem.trim(u8, input[content_start..end], &std.ascii.whitespace);
            if (body.len > 0) {
                var parts = std.mem.tokenizeScalar(u8, body, ' ');
                const target = parts.next() orelse body;
                const data = body[@min(target.len + 1, body.len)..];
                _ = callbacks.create_processing_instruction(callbacks.ctx, toStringSlice(target), toStringSlice(data));
            }
            i = if (end < input.len) end + 2 else input.len;
            continue;
        }

        if (i + 1 < input.len and input[i + 1] == '/') {
            var j = i + 2;
            skipWhitespace(input, &j);
            const tag_name = parseTagName(input, &j);
            const end = findTagEnd(input, j);
            popUntil(&stack, callbacks, tag_name, options.xml_mode);
            i = if (end < input.len) end + 1 else input.len;
            continue;
        }

        const end = findTagEnd(input, i + 1);
        var j = i + 1;
        skipWhitespace(input, &j);
        const tag_name = parseTagName(input, &j);
        var attrs = try parseAttributes(gpa, input[0..end], &j);
        defer attrs.deinit(gpa);

        var self_closing = false;
        var k = end;
        while (k > j and std.ascii.isWhitespace(input[k - 1])) : (k -= 1) {}
        if (k > j and input[k - 1] == '/') self_closing = true;
        if (!options.xml_mode and isVoidHtmlElement(tag_name)) self_closing = true;

        const ns = if (options.xml_mode) "http://www.w3.org/XML/1998/namespace" else "";
        if (try appendElement(callbacks, stack.items[stack.items.len - 1].node_ref, tag_name, attrs.items, ns)) |node_ref| {
            callbacks.append(callbacks.ctx, stack.items[stack.items.len - 1].node_ref, makeNodeOrTextNode(node_ref));
            if (!self_closing) {
                try stack.append(gpa, .{ .node_ref = node_ref, .tag_name = tag_name });
            } else {
                callbacks.pop(callbacks.ctx, node_ref);
            }
        }
        i = if (end < input.len) end + 1 else input.len;
    }

    while (stack.items.len > 1) {
        const entry = stack.pop().?;
        callbacks.pop(callbacks.ctx, entry.node_ref);
    }
}

export fn html5ever_attribute_iterator_next(ctx: *anyopaque) callconv(.c) h5e.Nullable(h5e.Attribute) {
    const iter: *AttrIterCtx = @ptrCast(@alignCast(ctx));
    if (iter.index >= iter.attrs.len) return h5e.Nullable(h5e.Attribute).none();
    const attr = iter.attrs[iter.index];
    iter.index += 1;
    return .{ .tag = 1, .value = attr };
}

export fn html5ever_attribute_iterator_count(ctx: *anyopaque) callconv(.c) usize {
    const iter: *AttrIterCtx = @ptrCast(@alignCast(ctx));
    return iter.attrs.len;
}

export fn html5ever_get_memory_usage() callconv(.c) h5e.MemoryUsage {
    return .{ .resident = 0, .allocated = 0 };
}

export fn html5ever_parse_document(
    html: [*c]const u8,
    len: usize,
    doc: *anyopaque,
    ctx: *anyopaque,
    createElementCallback: CreateElementCallback,
    elemNameCallback: ElemNameCallback,
    appendCallback: AppendCallback,
    parseErrorCallback: ParseErrorCallback,
    popCallback: PopCallback,
    createCommentCallback: CreateCommentCallback,
    createProcessingInstruction: CreateProcessingInstructionCallback,
    appendDoctypeToDocument: AppendDoctypeToDocumentCallback,
    addAttrsIfMissingCallback: AddAttrsIfMissingCallback,
    getTemplateContentsCallback: GetTemplateContentsCallback,
    removeFromParentCallback: RemoveFromParentCallback,
    reparentChildrenCallback: ReparentChildrenCallback,
    appendBeforeSiblingCallback: AppendBeforeSiblingCallback,
    appendBasedOnParentNodeCallback: AppendBasedOnParentNodeCallback,
) callconv(.c) void {
    const input = html[0..len];
    const callbacks: CallbackSet = .{
        .ctx = ctx,
        .create_element = createElementCallback,
        .elem_name = elemNameCallback,
        .append = appendCallback,
        .parse_error = parseErrorCallback,
        .pop = popCallback,
        .create_comment = createCommentCallback,
        .create_processing_instruction = createProcessingInstruction,
        .append_doctype_to_document = appendDoctypeToDocument,
        .add_attrs_if_missing = addAttrsIfMissingCallback,
        .get_template_contents = getTemplateContentsCallback,
        .remove_from_parent = removeFromParentCallback,
        .reparent_children = reparentChildrenCallback,
        .append_before_sibling = appendBeforeSiblingCallback,
        .append_based_on_parent_node = appendBasedOnParentNodeCallback,
    };
    parseDocumentLike(input, doc, callbacks, .{}) catch |err| {
        const msg = @errorName(err);
        callbacks.parse_error(ctx, toStringSlice(msg));
    };
}

export fn html5ever_parse_fragment(
    html: [*c]const u8,
    len: usize,
    doc: *anyopaque,
    ctx: *anyopaque,
    createElementCallback: CreateElementCallback,
    elemNameCallback: ElemNameCallback,
    appendCallback: AppendCallback,
    parseErrorCallback: ParseErrorCallback,
    popCallback: PopCallback,
    createCommentCallback: CreateCommentCallback,
    createProcessingInstruction: CreateProcessingInstructionCallback,
    appendDoctypeToDocument: AppendDoctypeToDocumentCallback,
    addAttrsIfMissingCallback: AddAttrsIfMissingCallback,
    getTemplateContentsCallback: GetTemplateContentsCallback,
    removeFromParentCallback: RemoveFromParentCallback,
    reparentChildrenCallback: ReparentChildrenCallback,
    appendBeforeSiblingCallback: AppendBeforeSiblingCallback,
    appendBasedOnParentNodeCallback: AppendBasedOnParentNodeCallback,
) callconv(.c) void {
    const input = html[0..len];
    const callbacks: CallbackSet = .{
        .ctx = ctx,
        .create_element = createElementCallback,
        .elem_name = elemNameCallback,
        .append = appendCallback,
        .parse_error = parseErrorCallback,
        .pop = popCallback,
        .create_comment = createCommentCallback,
        .create_processing_instruction = createProcessingInstruction,
        .append_doctype_to_document = appendDoctypeToDocument,
        .add_attrs_if_missing = addAttrsIfMissingCallback,
        .get_template_contents = getTemplateContentsCallback,
        .remove_from_parent = removeFromParentCallback,
        .reparent_children = reparentChildrenCallback,
        .append_before_sibling = appendBeforeSiblingCallback,
        .append_based_on_parent_node = appendBasedOnParentNodeCallback,
    };
    parseDocumentLike(input, doc, callbacks, .{ .fragment_mode = true }) catch |err| {
        const msg = @errorName(err);
        callbacks.parse_error(ctx, toStringSlice(msg));
    };
}

export fn xml5ever_parse_document(
    html: [*c]const u8,
    len: usize,
    doc: *anyopaque,
    ctx: *anyopaque,
    createElementCallback: CreateElementCallback,
    elemNameCallback: ElemNameCallback,
    appendCallback: AppendCallback,
    parseErrorCallback: ParseErrorCallback,
    popCallback: PopCallback,
    createCommentCallback: CreateCommentCallback,
    createProcessingInstruction: CreateProcessingInstructionCallback,
    appendDoctypeToDocument: AppendDoctypeToDocumentCallback,
    addAttrsIfMissingCallback: AddAttrsIfMissingCallback,
    getTemplateContentsCallback: GetTemplateContentsCallback,
    removeFromParentCallback: RemoveFromParentCallback,
    reparentChildrenCallback: ReparentChildrenCallback,
    appendBeforeSiblingCallback: AppendBeforeSiblingCallback,
    appendBasedOnParentNodeCallback: AppendBasedOnParentNodeCallback,
) callconv(.c) void {
    const input = html[0..len];
    const callbacks: CallbackSet = .{
        .ctx = ctx,
        .create_element = createElementCallback,
        .elem_name = elemNameCallback,
        .append = appendCallback,
        .parse_error = parseErrorCallback,
        .pop = popCallback,
        .create_comment = createCommentCallback,
        .create_processing_instruction = createProcessingInstruction,
        .append_doctype_to_document = appendDoctypeToDocument,
        .add_attrs_if_missing = addAttrsIfMissingCallback,
        .get_template_contents = getTemplateContentsCallback,
        .remove_from_parent = removeFromParentCallback,
        .reparent_children = reparentChildrenCallback,
        .append_before_sibling = appendBeforeSiblingCallback,
        .append_based_on_parent_node = appendBasedOnParentNodeCallback,
    };
    parseDocumentLike(input, doc, callbacks, .{ .xml_mode = true }) catch |err| {
        const msg = @errorName(err);
        callbacks.parse_error(ctx, toStringSlice(msg));
    };
}

export fn html5ever_streaming_parser_create(
    doc: *anyopaque,
    ctx: *anyopaque,
    createElementCallback: CreateElementCallback,
    elemNameCallback: ElemNameCallback,
    appendCallback: AppendCallback,
    parseErrorCallback: ParseErrorCallback,
    popCallback: PopCallback,
    createCommentCallback: CreateCommentCallback,
    createProcessingInstruction: CreateProcessingInstructionCallback,
    appendDoctypeToDocument: AppendDoctypeToDocumentCallback,
    addAttrsIfMissingCallback: AddAttrsIfMissingCallback,
    getTemplateContentsCallback: GetTemplateContentsCallback,
    removeFromParentCallback: RemoveFromParentCallback,
    reparentChildrenCallback: ReparentChildrenCallback,
    appendBeforeSiblingCallback: AppendBeforeSiblingCallback,
    appendBasedOnParentNodeCallback: AppendBasedOnParentNodeCallback,
) callconv(.c) ?*anyopaque {
    const parser = gpa.create(StreamingParser) catch return null;
    parser.* = .{
        .doc = doc,
        .callbacks = .{
            .ctx = ctx,
            .create_element = createElementCallback,
            .elem_name = elemNameCallback,
            .append = appendCallback,
            .parse_error = parseErrorCallback,
            .pop = popCallback,
            .create_comment = createCommentCallback,
            .create_processing_instruction = createProcessingInstruction,
            .append_doctype_to_document = appendDoctypeToDocument,
            .add_attrs_if_missing = addAttrsIfMissingCallback,
            .get_template_contents = getTemplateContentsCallback,
            .remove_from_parent = removeFromParentCallback,
            .reparent_children = reparentChildrenCallback,
            .append_before_sibling = appendBeforeSiblingCallback,
            .append_based_on_parent_node = appendBasedOnParentNodeCallback,
        },
        .xml_mode = false,
        .buffer = .empty,
    };
    return parser;
}

export fn html5ever_streaming_parser_feed(
    parser_ptr: *anyopaque,
    html: [*c]const u8,
    len: usize,
) callconv(.c) c_int {
    const parser: *StreamingParser = @ptrCast(@alignCast(parser_ptr));
    parser.buffer.appendSlice(gpa, html[0..len]) catch return 1;
    return 0;
}

export fn html5ever_streaming_parser_finish(parser_ptr: *anyopaque) callconv(.c) void {
    const parser: *StreamingParser = @ptrCast(@alignCast(parser_ptr));
    parseDocumentLike(parser.buffer.items, parser.doc, parser.callbacks, .{ .xml_mode = parser.xml_mode }) catch |err| {
        const msg = @errorName(err);
        parser.callbacks.parse_error(parser.callbacks.ctx, toStringSlice(msg));
    };
}

export fn html5ever_streaming_parser_destroy(parser_ptr: *anyopaque) callconv(.c) void {
    const parser: *StreamingParser = @ptrCast(@alignCast(parser_ptr));
    parser.deinit();
}
