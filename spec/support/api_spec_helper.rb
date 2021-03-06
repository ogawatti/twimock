module APISpecHelper
  shared_examples 'TestRackApplication 200 OK' do
    it 'should return 200 OK' do
      expect(last_response.status).to eq 200
      expect(last_response.body).to be_blank
      expect(last_response.header).to be_blank
    end
  end

  shared_examples 'API 401 UnAuthorized' do
    it 'should return 401 Unauthorized' do
      expect(last_response.status).to eq 401
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.header['Content-Type']).to eq "application/json; charset=utf-8"
      expect(last_response.body).not_to be_blank
      parsed_body = JSON.parse(last_response.body)
      expect(parsed_body["error"]["code"]).to match /^Invalid.*/
    end
  end

  shared_examples 'API 500 InternalServerError' do
    it 'should return 500' do
      expect(last_response.status).to eq 500
      expect(last_response.header).not_to be_blank
      expect(last_response.header['Content-Length']).to eq last_response.body.bytesize.to_s
      expect(last_response.body).not_to be_blank
    end
  end
end
