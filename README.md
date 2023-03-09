# v-requests
HTTP library for V.


## API
### fn (Client) delete
```v
fn (mut client Client) delete(url string, mut req_cfg ReqConfig) !http.Response
```
Sends an HTTP DELETE request to the given URL.

### fn (Client) get
```v
fn (mut client Client) get(url string, mut req_cfg ReqConfig) !http.Response
```
Sends an HTTP GET request to the given URL.

### fn (Client) head
```v
fn (mut client Client) head(url string, mut req_cfg ReqConfig) !http.Response
```
Sends an HTTP HEAD request to the given URL.

### fn (Client) patch
```v
fn (mut client Client) patch(url string, data string, mut req_cfg ReqConfig) !http.Response
```
Sends an HTTP PATCH request to the given URL.

### fn (Client) post
```v
fn (mut client Client) post(url string, data string, mut req_cfg ReqConfig) !http.Response
```
Sends an HTTP POST request to the given URL.

### fn (Client) put
```v
fn (mut client Client) put(url string, data string, mut req_cfg ReqConfig) !http.Response 
```
Sends an HTTP PUT request to the given URL.

### fn new_client
```v
fn new_client(mut config ClientConfig) &Client
```
Returns a new client object.

### fn (Client) post_multipart_form
```v
fn (mut client Client) post_multipart_form(url string, mut conf PostMultipartFormData, mut req_cfg ReqConfig) !http.Response
```
Sends multipart form data conf as an HTTP POST request to the given url.

### fn (Client) post_form
```v
fn (mut client Client) post_form(url string, data map[string]string, mut req_cfg ReqConfig) !http.Response
```
Sends the map data as X-WWW-FORM-URLENCODED data to an HTTP POST request to the given url.

### fn (Client) post_json
```v
fn (mut client Client) post_json(url string, data string, mut req_cfg ReqConfig) !http.Response
```
Sends the JSON data as an HTTP POST request to the given url.

### fn (Client) get_text
```v
fn (mut client Client) get_text(url string, mut req_cfg ReqConfig) !string
```
Sends an HTTP GET request to the given url and returns the text content of the response.

### fn (Client) download_file
```v
fn (mut client Client) download_file(url string, out_file_path string, mut req_cfg ReqConfig) !
```
Downloads the content from the given URL and writes it to the output file path. All the content will be loaded into memory.

### fn (Client) download_file_chunked
```v
fn (mut client Client) download_file_chunked(url string, out_file_path string, mut req_cfg ReqConfig, cb fn (DownloadProgress)) !
```
Downloads the content from the given URL and writes it to the output file path in chunks. The progress callback will be called after each chunk is written. The server must provide a content length and an accept ranges header with "bytes."

### fn (Client) set_cookies
```v
fn (mut client Client) set_cookies(cookies map[string]string)
```
Sets the client's cookies, removing all previous ones.

### fn (Client) update_cookies
```v
fn (mut client Client) update_cookies(cookies map[string]string)
```
Updates the client's cookies with the provided ones.

### fn (Client) clear_cookies
```v
fn (mut client Client) clear_cookies(cookies map[string]string)
```
Clears the client's cookies.

### fn (Client) set_headers
```v
fn (mut client Client) set_headers(headers map[string]string)
```
Sets the client's headers, removing all previous ones.

### fn (Client) set_headers
```v
fn (mut client Client) update_headers(headers map[string]string)
```
Updates the client's headers with the provided ones.
