module vrequests

import net.http
import net.urllib
import os
import rand
import strings
import time
import sorrow446.vhumanise

const (
	chunk_size = 1048575 // 1MB - 1 byte
	content_type_default = 'text/plain'
)

pub fn new_client(mut config ClientConfig) &Client {
	mut client := &Client{}

	client.max_redirects = config.max_redirects
	if config.cookies.len > 0 {
		client.cookies = config.cookies.clone()
	}
	if config.headers.len > 0 {
		client.headers = config.headers.clone()
	}
	return client
}

fn fetch_and_set(mut client Client, mut fetch_cfg http.FetchConfig, req_cfg ReqConfig) !http.Response {
    fetch_cfg.cookies = client.cookies.clone()
    fetch_cfg.validate = req_cfg.validate

    mut max_redirects := client.max_redirects

   	if req_cfg.max_redirects > 0 {
   		max_redirects = req_cfg.max_redirects
   	}
	
	if req_cfg.cookies.len > 0 {
		for k, v in req_cfg.cookies {
			fetch_cfg.cookies[k] = v
		}
	}

	mut merged_headers := client.headers.clone()
	if req_cfg.headers.len > 0 {
		for k, v in req_cfg.headers {
			merged_headers[k] = v
		}
	}	

	if merged_headers.len > 0 {
		fetch_cfg.header = http.new_custom_header_from_map(merged_headers)!
	}

	orig_allow_redirects := req_cfg.allow_redirects
	if orig_allow_redirects {
		fetch_cfg.allow_redirect = false
	}
	
	mut resp := http.Response{}
	mut parsed_url := urllib.parse(fetch_cfg.url) or {
		return err
	}
	mut num_redirects := 0

	// follow redirects manually so we can get the cookies from each req
	for {
		if num_redirects > max_redirects {
				return IError(TooManyRedirects{
					num: num_redirects,
					max: max_redirects
				})
		}
		resp = http.fetch(fetch_cfg)!

		if req_cfg.set_cookies {
			ret_cookies := resp.cookies()
			if ret_cookies.len > 0 {
			    for c in ret_cookies {
				   	client.cookies[c.name] = c.value
				}
			}
		}
	
		if !orig_allow_redirects {
			break
		}
		if resp.status() !in [.moved_permanently, .found, .see_other, .temporary_redirect,
			.permanent_redirect] {
			break
		}

		mut redirect_url := resp.header.get(.location) or { '' }

		parsed_redir_url := urllib.parse(redirect_url) or {
			return error('invalid URL in redirect "${redirect_url}"')
		}

		if redirect_url.len > 0 && redirect_url[0] == `/` {
			parsed_url.set_path(redirect_url) or {
				return error('invalid path in redirect: "${redirect_url}"')
			}
			redirect_url = parsed_url.str()
		}

		parsed_url = parsed_redir_url
		fetch_cfg.url = redirect_url
		num_redirects++
	}
	return resp
}

pub fn (mut client Client) set_cookies(cookies map[string]string) {
	client.cookies = cookies.clone()
}

pub fn (mut client Client) update_cookies(cookies map[string]string) {
	for k, v in cookies {
		client.cookies[k] = v
	}
}

pub fn (mut client Client) clear_cookies(cookies map[string]string) {
	client.cookies.clear()
}

pub fn (mut client Client) set_headers(headers map[string]string) {
	client.headers = headers.clone()
}

pub fn (mut client Client) update_headers(headers map[string]string) {
	for k, v in headers {
		client.headers[k] = v
	}
}

pub fn (mut client Client) get(url string, mut req_cfg ReqConfig) !http.Response {
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.get
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) get_text(url string, mut req_cfg ReqConfig) !string {
	req := client.get(url, mut req_cfg)!
	if req.status() != .ok {
		return error('received http code ${req.status_code}')
	}
	return req.body
}

pub fn (mut client Client) post(url string, data string, mut req_cfg ReqConfig) !http.Response {
	req_cfg.headers['Content-Type'] = content_type_default
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.post,
        data: data,
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) post_json(url string, data string, mut req_cfg ReqConfig) !http.Response {
	req_cfg.headers['Content-Type'] = 'application/json'
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.post,
        data: data
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) post_form(url string, data map[string]string, mut req_cfg ReqConfig) !http.Response {
	req_cfg.headers['Content-Type'] = 'application/x-www-form-urlencoded'
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.post,
        data: http.url_encode_form_data(data),
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

// from net.http
fn multipart_form_body(form map[string]string, files map[string][]http.FileData) (string, string) {
	alpha_numeric := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
	boundary := rand.string_from_set(alpha_numeric, 64)

	mut sb := strings.new_builder(1024)
	for name, value in form {
		sb.write_string('\r\n--')
		sb.write_string(boundary)
		sb.write_string('\r\nContent-Disposition: form-data; name="')
		sb.write_string(name)
		sb.write_string('"\r\n\r\n')
		sb.write_string(value)
	}
	for name, fs in files {
		for f in fs {
			sb.write_string('\r\n--')
			sb.write_string(boundary)
			sb.write_string('\r\nContent-Disposition: form-data; name="')
			sb.write_string(name)
			sb.write_string('"; filename="')
			sb.write_string(f.filename)
			sb.write_string('"\r\nContent-Type: ')
			sb.write_string(f.content_type)
			sb.write_string('\r\n\r\n')
			sb.write_string(f.data)
		}
	}
	sb.write_string('\r\n--')
	sb.write_string(boundary)
	sb.write_string('--')
	return sb.str(), boundary
}

pub fn (mut client Client) post_multipart_form(url string, mut conf PostMultipartFormData, mut req_cfg ReqConfig) !http.Response {
	body, boundary := multipart_form_body(conf.form, conf.files)
	req_cfg.headers['Content-Type'] = 'multipart/form-data; boundary="${boundary}"'

	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.post,
        data: body,
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) patch(url string, data string, mut req_cfg ReqConfig) !http.Response {
	req_cfg.headers['Content-Type'] = content_type_default
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.patch,
        data: data,
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) put(url string, data string, mut req_cfg ReqConfig) !http.Response {
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.put,
        data: data
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) head(url string, mut req_cfg ReqConfig) !http.Response {
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.head
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}

pub fn (mut client Client) delete(url string, mut req_cfg ReqConfig) !http.Response {
	mut fetch_cfg := http.FetchConfig{
        url: url,
        method: http.Method.delete
	}
	return fetch_and_set(mut client, mut fetch_cfg, req_cfg)
}


pub fn (mut client Client) download_file(url string, out_file_path string, mut req_cfg ReqConfig) ! {
	body := client.get_text(url, mut req_cfg)!
	os.write_file(out_file_path, body)!
}

fn probe_file(mut client Client, url string, mut req_cfg ReqConfig) !int {
	req := client.head(url, mut req_cfg)!
	size_str := req.header.get(.content_length) or {
		return error('server didn\'t return a content length header')
	}
	size := size_str.int()
	if size < 1 {
		return error('bad content length header')
	}

	accept_range := req.header.get(.accept_ranges) or { '' }
	if accept_range != 'bytes' {
		return error('server doesn\'t support byte ranges')
	}
	return size
}

pub fn (mut client Client) download_file_chunked(url string, out_file_path string, mut req_cfg ReqConfig, cb fn (DownloadProgress)) ! {
	mut speed := i64(0)
	mut start_byte := 0
	mut last := false
	mut end_byte := chunk_size

	size := probe_file(mut client, url, mut req_cfg)!

	if size <= chunk_size {
		end_byte = size-1
		last = true
	}
	
	mut f := os.open_file(out_file_path, 'wb+', 0o755)!
	defer { f.close() }

	mut p := DownloadProgress{
		total_bytes: size
		total_hum: vhumanise.bytes(u64(size))
		start_time: time.now().unix*1000
	}

	for {
		mut expected_len := end_byte-start_byte+1
		// if last {
		// 	expected_len--
		// }

		req_cfg.headers['Range'] = 'bytes=${start_byte}-${end_byte}'
		resp := client.get(url, mut req_cfg)!
		ret_len := resp.header.get(.content_length) or {
			return error('server didn\'t return a content length header')
		}
		//println(ret_len)
		if ret_len.int() != expected_len {
			return error('bad content length, expected ${expected_len}, got ${ret_len}')
		}
		f.write_string(resp.body)!

		start_byte = end_byte+1
		p.bytes_downloaded = start_byte
		percentage := f64(p.bytes_downloaded) / f64(p.total_bytes) * f64(100)
		p.percentage = int(percentage)
		p.downloaded_hum = vhumanise.bytes(u64(start_byte))
		to_divide_by := time.now().unix*1000 - p.start_time
		if to_divide_by != 0 {
			speed = p.bytes_downloaded /  to_divide_by * 1000
		}
		p.speed = vhumanise.bytes(u64(speed))
		cb(p)

		if last {
			break
		}
		end_byte += chunk_size+1
		if size <= end_byte+1 {
			last = true
			end_byte = size-1
		}
	}
}