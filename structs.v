module vrequests

import net.http

pub struct ClientConfig {
pub mut:
	cookies map[string]string
	headers map[string]string
	max_redirects int = 4
}

pub struct Client {
pub mut:
	cookies map[string]string
	headers map[string]string
	max_redirects int
}

pub struct ReqConfig {
pub mut:
	cookies map[string]string
	headers map[string]string
	allow_redirects bool = true
	validate bool = true
	max_redirects int
	set_cookies bool = true
}

pub struct PostMultipartFormData {
pub mut:
	form   map[string]string
	files  map[string][]http.FileData
}

pub struct DownloadProgress {
pub mut:
	bytes_downloaded i64
	downloaded_hum string
	total_bytes i64
	total_hum string
	percentage int
	speed string
mut:
	start_time i64
}