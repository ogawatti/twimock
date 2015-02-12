module APISpecHelper
  shared_context '401 Unauthorizaed Intent Sessions', assert: :UnauthorizedRequestToken do
    it 'should return 401 Unauthorized' do
      expect(last_response.status).to eq 401
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.header['Content-Type']).to eq "application/json; charset=utf-8"
      expect(last_response.body).not_to be_blank
      parsed_body = JSON.parse(last_response.body)
      expect(parsed_body["error"]["code"]).to eq "InvalidRequestToken"
    end
  end
end
