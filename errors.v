module vrequests

pub struct TooManyRedirects {
	Error
	num int
	max int
}

fn (err TooManyRedirects) msg() string {
	return 'maximum number of redirects reached (${err.num}/${err.max})'
}