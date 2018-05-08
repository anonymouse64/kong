use strict;
use warnings FATAL => 'all';
use Test::Nginx::Socket::Lua;

$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();

plan tests => repeat_each() * (blocks() * 3);

run_tests();

__DATA__

=== TEST 1: response.set_status() code must be a number
--- config
    location = /t {
        content_by_lua_block {
            ngx.send_headers()

            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local ok, err = pcall(sdk.response.set_status)
            if not ok then
                ngx.say(err)
            end
        }
    }
--- request
GET /t
--- response_body
code must be a number
--- no_error_log
[error]



=== TEST 2: response.set_status() code must be a number between 100 and 599
--- config
    location = /t {
        content_by_lua_block {
            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local ok1, err1 = pcall(sdk.response.set_status, 99)
            local ok2, err2 = pcall(sdk.response.set_status, 200)
            local ok3, err3 = pcall(sdk.response.set_status, 600)

            if not ok1 then
                ngx.say(err1)
            end

            if ok2 then
                ngx.say("ok")
            end

            if not ok3 then
                ngx.print(err3)
            end
        }
    }
--- request
GET /t
--- response_body chop
code must be a number between 100 and 599
ok
code must be a number between 100 and 599
--- no_error_log
[error]



=== TEST 3: response.set_status() errors if headers have already been sent
--- config
    location = /t {
        content_by_lua_block {
            ngx.send_headers()

            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            local ok, err = pcall(sdk.response.set_status, 500)
            if not ok then
                ngx.say(err)
            end
        }
    }
--- request
GET /t
--- response_body
headers have been sent
--- no_error_log
[error]



=== TEST 4: response.set_status() sets response status code
--- http_config
    server {
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        location /t {
            content_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new()

                sdk.response.set_status(204)
            }
        }
    }
--- config
    location = /t {
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        header_filter_by_lua_block {
            ngx.header.content_length = nil
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "Status: " .. ngx.status
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- error_code: 204
--- response_body chop
Status: 204
--- no_error_log
[error]



=== TEST 5: response.set_status() replaces response status code
--- http_config
    server {
        listen unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        location /t {
            content_by_lua_block {
                local SDK = require "kong.sdk"
                local sdk = SDK.new()

                sdk.response.set_status(204)
            }
        }
    }
--- config
    location = /t {
        proxy_pass http://unix:$TEST_NGINX_HTML_DIR/nginx.sock;

        header_filter_by_lua_block {
            ngx.header.content_length = nil

            local SDK = require "kong.sdk"
            local sdk = SDK.new()

            sdk.response.set_status(200)
        }

        body_filter_by_lua_block {
            ngx.arg[1] = "Status: " .. ngx.status
            ngx.arg[2] = true
        }
    }
--- request
GET /t
--- error_code: 200
--- response_body chop
Status: 200
--- no_error_log
[error]
