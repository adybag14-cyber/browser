pub const CURL = anyopaque;
pub const CURLM = anyopaque;

pub const curl_off_t = c_longlong;
pub const curl_socket_t = usize;

pub const CURLcode = c_int;
pub const CURLMcode = c_int;
pub const CURLHcode = c_int;
pub const CURLoption = c_int;
pub const CURLMoption = c_int;
pub const CURLINFO = c_int;
pub const CURLMSG = c_int;
pub const curl_infotype = c_int;

pub const curl_debug_callback = ?*const fn (?*CURL, curl_infotype, [*c]u8, usize, ?*anyopaque) callconv(.c) c_int;
pub const curl_write_callback = ?*const fn ([*c]u8, usize, usize, ?*anyopaque) callconv(.c) usize;

pub const struct_curl_slist = extern struct {
    data: [*c]u8 = null,
    next: [*c]struct_curl_slist = null,
};
pub const curl_slist = struct_curl_slist;

pub const struct_curl_httppost = extern struct {
    next: [*c]struct_curl_httppost = null,
    name: [*c]u8 = null,
    namelength: c_long = 0,
    contents: [*c]u8 = null,
    contentslength: c_long = 0,
    buffer: [*c]u8 = null,
    bufferlength: c_long = 0,
    contenttype: [*c]u8 = null,
    contentheader: [*c]struct_curl_slist = null,
    more: [*c]struct_curl_httppost = null,
    flags: c_long = 0,
    showfilename: [*c]u8 = null,
    userp: ?*anyopaque = null,
    contentlen: curl_off_t = 0,
};
pub const curl_httppost = struct_curl_httppost;

pub const struct_curl_blob = extern struct {
    data: ?*anyopaque = null,
    len: usize = 0,
    flags: c_uint = 0,
};
pub const curl_blob = struct_curl_blob;

pub const union_CURLMsgData = extern union {
    whatever: ?*anyopaque,
    result: CURLcode,
};

pub const struct_CURLMsg = extern struct {
    msg: CURLMSG = 0,
    easy_handle: ?*CURL = null,
    data: union_CURLMsgData = .{ .whatever = null },
};
pub const CURLMsg = struct_CURLMsg;

pub const struct_curl_waitfd = extern struct {
    fd: curl_socket_t = 0,
    events: c_short = 0,
    revents: c_short = 0,
};
pub const curl_waitfd = struct_curl_waitfd;

pub const struct_curl_header = extern struct {
    name: [*c]u8 = null,
    value: [*c]u8 = null,
    amount: usize = 0,
    index: usize = 0,
    origin: c_uint = 0,
    anchor: ?*anyopaque = null,
};
pub const curl_header = struct_curl_header;

pub const CURLINFO_TEXT: c_int = 0;
pub const CURLINFO_HEADER_IN: c_int = 1;
pub const CURLINFO_HEADER_OUT: c_int = 2;
pub const CURLINFO_DATA_IN: c_int = 3;
pub const CURLINFO_DATA_OUT: c_int = 4;
pub const CURLINFO_SSL_DATA_IN: c_int = 5;
pub const CURLINFO_SSL_DATA_OUT: c_int = 6;
pub const CURLINFO_END: c_int = 7;

pub const CURLE_OK: c_int = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: c_int = 1;
pub const CURLE_FAILED_INIT: c_int = 2;
pub const CURLE_URL_MALFORMAT: c_int = 3;
pub const CURLE_NOT_BUILT_IN: c_int = 4;
pub const CURLE_COULDNT_RESOLVE_PROXY: c_int = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: c_int = 6;
pub const CURLE_COULDNT_CONNECT: c_int = 7;
pub const CURLE_WEIRD_SERVER_REPLY: c_int = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: c_int = 9;
pub const CURLE_FTP_ACCEPT_FAILED: c_int = 10;
pub const CURLE_FTP_WEIRD_PASS_REPLY: c_int = 11;
pub const CURLE_FTP_ACCEPT_TIMEOUT: c_int = 12;
pub const CURLE_FTP_WEIRD_PASV_REPLY: c_int = 13;
pub const CURLE_FTP_WEIRD_227_FORMAT: c_int = 14;
pub const CURLE_FTP_CANT_GET_HOST: c_int = 15;
pub const CURLE_HTTP2: c_int = 16;
pub const CURLE_FTP_COULDNT_SET_TYPE: c_int = 17;
pub const CURLE_PARTIAL_FILE: c_int = 18;
pub const CURLE_FTP_COULDNT_RETR_FILE: c_int = 19;
pub const CURLE_QUOTE_ERROR: c_int = 21;
pub const CURLE_HTTP_RETURNED_ERROR: c_int = 22;
pub const CURLE_WRITE_ERROR: c_int = 23;
pub const CURLE_UPLOAD_FAILED: c_int = 25;
pub const CURLE_READ_ERROR: c_int = 26;
pub const CURLE_OUT_OF_MEMORY: c_int = 27;
pub const CURLE_OPERATION_TIMEDOUT: c_int = 28;
pub const CURLE_FTP_PORT_FAILED: c_int = 30;
pub const CURLE_FTP_COULDNT_USE_REST: c_int = 31;
pub const CURLE_RANGE_ERROR: c_int = 33;
pub const CURLE_SSL_CONNECT_ERROR: c_int = 35;
pub const CURLE_BAD_DOWNLOAD_RESUME: c_int = 36;
pub const CURLE_FILE_COULDNT_READ_FILE: c_int = 37;
pub const CURLE_LDAP_CANNOT_BIND: c_int = 38;
pub const CURLE_LDAP_SEARCH_FAILED: c_int = 39;
pub const CURLE_ABORTED_BY_CALLBACK: c_int = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: c_int = 43;
pub const CURLE_INTERFACE_FAILED: c_int = 45;
pub const CURLE_TOO_MANY_REDIRECTS: c_int = 47;
pub const CURLE_UNKNOWN_OPTION: c_int = 48;
pub const CURLE_SETOPT_OPTION_SYNTAX: c_int = 49;
pub const CURLE_GOT_NOTHING: c_int = 52;
pub const CURLE_SSL_ENGINE_NOTFOUND: c_int = 53;
pub const CURLE_SSL_ENGINE_SETFAILED: c_int = 54;
pub const CURLE_SEND_ERROR: c_int = 55;
pub const CURLE_RECV_ERROR: c_int = 56;
pub const CURLE_SSL_CERTPROBLEM: c_int = 58;
pub const CURLE_SSL_CIPHER: c_int = 59;
pub const CURLE_PEER_FAILED_VERIFICATION: c_int = 60;
pub const CURLE_BAD_CONTENT_ENCODING: c_int = 61;
pub const CURLE_FILESIZE_EXCEEDED: c_int = 63;
pub const CURLE_USE_SSL_FAILED: c_int = 64;
pub const CURLE_SEND_FAIL_REWIND: c_int = 65;
pub const CURLE_SSL_ENGINE_INITFAILED: c_int = 66;
pub const CURLE_LOGIN_DENIED: c_int = 67;
pub const CURLE_TFTP_NOTFOUND: c_int = 68;
pub const CURLE_TFTP_PERM: c_int = 69;
pub const CURLE_REMOTE_DISK_FULL: c_int = 70;
pub const CURLE_TFTP_ILLEGAL: c_int = 71;
pub const CURLE_TFTP_UNKNOWNID: c_int = 72;
pub const CURLE_REMOTE_FILE_EXISTS: c_int = 73;
pub const CURLE_TFTP_NOSUCHUSER: c_int = 74;
pub const CURLE_SSL_CACERT_BADFILE: c_int = 77;
pub const CURLE_REMOTE_FILE_NOT_FOUND: c_int = 78;
pub const CURLE_SSH: c_int = 79;
pub const CURLE_SSL_SHUTDOWN_FAILED: c_int = 80;
pub const CURLE_AGAIN: c_int = 81;
pub const CURLE_SSL_CRL_BADFILE: c_int = 82;
pub const CURLE_SSL_ISSUER_ERROR: c_int = 83;
pub const CURLE_FTP_PRET_FAILED: c_int = 84;
pub const CURLE_RTSP_CSEQ_ERROR: c_int = 85;
pub const CURLE_RTSP_SESSION_ERROR: c_int = 86;
pub const CURLE_FTP_BAD_FILE_LIST: c_int = 87;
pub const CURLE_CHUNK_FAILED: c_int = 88;
pub const CURLE_NO_CONNECTION_AVAILABLE: c_int = 89;
pub const CURLE_SSL_PINNEDPUBKEYNOTMATCH: c_int = 90;
pub const CURLE_SSL_INVALIDCERTSTATUS: c_int = 91;
pub const CURLE_HTTP2_STREAM: c_int = 92;
pub const CURLE_RECURSIVE_API_CALL: c_int = 93;
pub const CURLE_AUTH_ERROR: c_int = 94;
pub const CURLE_HTTP3: c_int = 95;
pub const CURLE_QUIC_CONNECT_ERROR: c_int = 96;
pub const CURLE_PROXY: c_int = 97;
pub const CURLE_SSL_CLIENTCERT: c_int = 98;
pub const CURLE_UNRECOVERABLE_POLL: c_int = 99;
pub const CURLE_TOO_LARGE: c_int = 100;

pub const CURLOPT_WRITEDATA: c_int = 10001;
pub const CURLOPT_URL: c_int = 10002;
pub const CURLOPT_PROXY: c_int = 10004;
pub const CURLOPT_PROXYUSERPWD: c_int = 10006;
pub const CURLOPT_WRITEFUNCTION: c_int = 20011;
pub const CURLOPT_COOKIE: c_int = 10022;
pub const CURLOPT_HTTPHEADER: c_int = 10023;
pub const CURLOPT_HTTPPOST: c_int = 10024;
pub const CURLOPT_HEADERDATA: c_int = 10029;
pub const CURLOPT_CUSTOMREQUEST: c_int = 10036;
pub const CURLOPT_VERBOSE: c_int = 41;
pub const CURLOPT_POST: c_int = 47;
pub const CURLOPT_FOLLOWLOCATION: c_int = 52;
pub const CURLOPT_POSTFIELDSIZE: c_int = 60;
pub const CURLOPT_SSL_VERIFYPEER: c_int = 64;
pub const CURLOPT_MAXREDIRS: c_int = 68;
pub const CURLOPT_HEADERFUNCTION: c_int = 20079;
pub const CURLOPT_HTTPGET: c_int = 80;
pub const CURLOPT_HTTP_VERSION: c_int = 84;
pub const CURLOPT_SSL_VERIFYHOST: c_int = 81;
pub const CURLOPT_DEBUGFUNCTION: c_int = 20094;
pub const CURLOPT_IPRESOLVE: c_int = 113;
pub const CURLOPT_ACCEPT_ENCODING: c_int = 10102;
pub const CURLOPT_PRIVATE: c_int = 10103;
pub const CURLOPT_TIMEOUT_MS: c_int = 155;
pub const CURLOPT_CONNECTTIMEOUT_MS: c_int = 156;
pub const CURLOPT_COPYPOSTFIELDS: c_int = 10165;
pub const CURLOPT_NOPROXY: c_int = 10177;
pub const CURLOPT_PROXY_SSL_VERIFYPEER: c_int = 248;
pub const CURLOPT_PROXY_SSL_VERIFYHOST: c_int = 249;
pub const CURLOPT_CAINFO_BLOB: c_int = 40309;
pub const CURLOPT_PROXY_CAINFO_BLOB: c_int = 40310;
pub const CURLOPT_REDIR_PROTOCOLS_STR: c_int = 10319;
pub const CURL_IPRESOLVE_WHATEVER: c_int = 0;
pub const CURL_IPRESOLVE_V4: c_int = 1;
pub const CURL_IPRESOLVE_V6: c_int = 2;
pub const CURL_HTTP_VERSION_NONE: c_int = 0;
pub const CURL_HTTP_VERSION_1_1: c_int = 2;
pub const CURL_HTTP_VERSION_2_0: c_int = 3;
pub const CURL_HTTP_VERSION_2TLS: c_int = 4;

pub const CURLINFO_EFFECTIVE_URL: c_int = 1048577;
pub const CURLINFO_RESPONSE_CODE: c_int = 2097154;
pub const CURLINFO_REDIRECT_COUNT: c_int = 2097172;
pub const CURLINFO_PRIVATE: c_int = 1048597;

pub const CURLM_CALL_MULTI_PERFORM: c_int = -1;
pub const CURLM_OK: c_int = 0;
pub const CURLM_BAD_HANDLE: c_int = 1;
pub const CURLM_BAD_EASY_HANDLE: c_int = 2;
pub const CURLM_OUT_OF_MEMORY: c_int = 3;
pub const CURLM_INTERNAL_ERROR: c_int = 4;
pub const CURLM_BAD_SOCKET: c_int = 5;
pub const CURLM_UNKNOWN_OPTION: c_int = 6;
pub const CURLM_ADDED_ALREADY: c_int = 7;
pub const CURLM_RECURSIVE_API_CALL: c_int = 8;
pub const CURLM_WAKEUP_FAILURE: c_int = 9;
pub const CURLM_BAD_FUNCTION_ARGUMENT: c_int = 10;
pub const CURLM_ABORTED_BY_CALLBACK: c_int = 11;
pub const CURLM_UNRECOVERABLE_POLL: c_int = 12;

pub const CURLMSG_NONE: c_int = 0;
pub const CURLMSG_DONE: c_int = 1;
pub const CURLMSG_LAST: c_int = 2;
pub const CURLMOPT_MAX_HOST_CONNECTIONS: c_int = 7;

pub const CURLHE_OK: c_int = 0;
pub const CURLHE_BADINDEX: c_int = 1;
pub const CURLHE_MISSING: c_int = 2;
pub const CURLHE_NOHEADERS: c_int = 3;
pub const CURLHE_NOREQUEST: c_int = 4;
pub const CURLHE_OUT_OF_MEMORY: c_int = 5;
pub const CURLHE_BAD_ARGUMENT: c_int = 6;
pub const CURLHE_NOT_BUILT_IN: c_int = 7;

pub const CURL_WRITEFUNC_ERROR: usize = 0xffffffff;
pub const CURL_GLOBAL_SSL: c_int = 1;
pub const CURL_GLOBAL_WIN32: c_int = 2;
pub const CURL_WAIT_POLLIN: c_int = 0x0001;
pub const CURL_WAIT_POLLPRI: c_int = 0x0002;
pub const CURL_WAIT_POLLOUT: c_int = 0x0004;
pub const CURLH_HEADER: c_int = 1;
pub const CURLH_TRAILER: c_int = 2;
pub const CURLH_CONNECT: c_int = 4;
pub const CURLH_1XX: c_int = 8;
pub const CURLH_PSEUDO: c_int = 16;

pub extern fn curl_global_init(flags: c_long) CURLcode;
pub extern fn curl_global_cleanup() void;
pub extern fn curl_version() [*c]u8;
pub extern fn curl_easy_init() ?*CURL;
pub extern fn curl_easy_cleanup(curl: ?*CURL) void;
pub extern fn curl_easy_perform(curl: ?*CURL) CURLcode;
pub extern fn curl_easy_setopt(curl: ?*CURL, option: CURLoption, ...) CURLcode;
pub extern fn curl_easy_getinfo(curl: ?*CURL, info: CURLINFO, ...) CURLcode;
pub extern fn curl_easy_header(easy: ?*CURL, name: [*c]const u8, index: usize, origin: c_uint, request: c_int, hout: [*c][*c]struct_curl_header) CURLHcode;
pub extern fn curl_easy_nextheader(easy: ?*CURL, origin: c_uint, request: c_int, prev: [*c]struct_curl_header) [*c]struct_curl_header;

pub extern fn curl_multi_init() ?*CURLM;
pub extern fn curl_multi_cleanup(multi_handle: ?*CURLM) CURLMcode;
pub extern fn curl_multi_add_handle(multi_handle: ?*CURLM, curl_handle: ?*CURL) CURLMcode;
pub extern fn curl_multi_remove_handle(multi_handle: ?*CURLM, curl_handle: ?*CURL) CURLMcode;
pub extern fn curl_multi_perform(multi_handle: ?*CURLM, running_handles: [*c]c_int) CURLMcode;
pub extern fn curl_multi_poll(multi_handle: ?*CURLM, extra_fds: [*c]struct_curl_waitfd, extra_nfds: c_uint, timeout_ms: c_int, ret: [*c]c_int) CURLMcode;
pub extern fn curl_multi_info_read(multi_handle: ?*CURLM, msgs_in_queue: [*c]c_int) [*c]CURLMsg;
pub extern fn curl_multi_setopt(multi_handle: ?*CURLM, option: CURLMoption, ...) CURLMcode;

pub extern fn curl_slist_append(list: [*c]curl_slist, header: [*c]const u8) [*c]curl_slist;
pub extern fn curl_slist_free_all(list: [*c]curl_slist) void;
