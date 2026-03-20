const c = @import("v8.zig").c;

pub export fn v8_inspector__Client__IMPL__valueSubtype(
    _: *c.InspectorClientImpl,
    value: *const c.Value,
) callconv(.c) [*c]const u8 {
    _ = value;
    return null;
}

pub export fn v8_inspector__Client__IMPL__descriptionForValueSubtype(
    _: *c.InspectorClientImpl,
    context: *const c.Context,
    value: *const c.Value,
) callconv(.c) [*c]const u8 {
    _ = value;
    _ = context;
    return null;
}
