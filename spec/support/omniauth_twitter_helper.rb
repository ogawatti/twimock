module OmniAuthTwitterHelper
  def create_request_env(request_token, request_secret)
    { 
      'rack.input'   => StringIO.new(""),
      'rack.session' => { "session_id" => "123456",
                          "callback_path" => "/",
                          "omniauth.params" => {},
                          "omniauth.origin" => "http://example.com/authentication",
                          "oauth" => { "twitter" => { "callback_confirmed" => true,
                                                      "request_token"  => request_token,
                                                      "request_secret" => request_secret } } },
      'rack.url_scheme'   => "http",
      "GATEWAY_INTERFACE" => "CGI/1.1",
      "PATH_INFO"         => "/users/auth/twitter",
      "QUERY_STRING"      => "",
      "REMOTE_ADDR"       => "127.0.0.1",
      "REMOTE_HOST"       => "localhost.localdomain",
      "REQUEST_METHOD"    => "GET",
      "REQUEST_URI"       => "http://example.com/users/auth/twitter",
      "SERVER_NAME"       => "example.com",
      "SERVER_PORT"       => "80",
      "SERVER_PROTOCOL"   => "HTTP/1.1",
      "HTTP_HOST"         => "example.com",
    }
  end
end
