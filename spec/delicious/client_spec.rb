require 'spec_helper'

describe Delicious::Client do
  let(:client) do
    described_class.new do |config|
      config.access_token = 'my-access-token'
    end
  end

  describe 'configuration' do
    it 'sets access_token to my-access-token' do
      expect(client.access_token).to eq 'my-access-token'
    end

    it 'sets access_token to another-access-token' do
      another_client = described_class.new { |config| config.access_token = 'another-access-token' }
      expect(another_client.access_token).to eq 'another-access-token'
    end
  end

  context 'requests' do
    let(:result) { :success }
    let(:success_body) { '<?xml version="1.0" encoding="UTF-8"?><result code="done"/>' }
    let(:failure_boby) { '<?xml version="1.0" encoding="UTF-8"?><result code="error adding link"/>' }
    before do
      body = result == :failure ? failure_boby : success_body
      @request = stub_request(:post, endpoint)
        .to_return body: body, headers: {'Content-Type' => 'text/xml; charset=UTF-8'}
    end

    describe '#post' do
      let(:endpoint) { 'https://previous.delicious.com/v1/posts/add' }

      let(:attrs) do
        { url:         'http://example.com/cool-blog-post',
          description: 'Cool post, eh?',
          extended:    'Extended info',
          tags:        'tag1, tag2',
          dt:          '2014-05-04T22:01:00Z',
          replace:     'no',
          shared:      'no'
        }
      end
      let(:post) { client.post attrs }

      context 'valid attributes given' do
        it 'adds "Authorization: Bearer my-access-token" header' do
          post
          expect(WebMock).to have_requested(:post, endpoint)
            .with(headers: { 'Authorization' => 'Bearer my-access-token' })
        end

        context 'params' do
          it 'sends url=http://example.com/cool-blog-post' do
            post
            expect(WebMock).to have_requested(:post, endpoint).with { |r| assert_param(r, 'url', 'http://example.com/cool-blog-post') }
          end

          it 'sends description=Cool post, eh?' do
            post
            expect(WebMock).to have_requested(:post, endpoint).with { |r| assert_param(r, 'description', 'Cool post, eh?') }
          end
        end

        describe 'result' do
          subject { post }

          context 'success' do
            let(:result) { :success }

            it { should be_an_instance_of Delicious::Post }
            it 'has url' do
              expect(subject.url).to eq 'http://example.com/cool-blog-post'
            end
            it 'returns not persisted Post object' do
              expect(subject).to be_persisted
            end
          end

          context 'failure' do
            let(:result) { :failure }

            it 'throws an error' do
              expect { subject }.to raise_error
            end
          end
        end
      end

      context 'invalid attributes given' do
        let(:attrs) do
          { description: 'Cool site' }
        end

        it 'does not sends request' do
          post
          expect(WebMock).not_to have_requested(:post, endpoint)
        end

        it 'returns invalid Post object' do
          p = post
          expect(p).not_to be_valid
        end

        it 'returns not persisted Post object' do
          p = post
          expect(p).not_to be_persisted
        end
      end
    
      after { remove_request_stub @request }
    end

    describe '#delete' do
      let(:endpoint) { 'https://previous.delicious.com/v1/posts/delete' }
      let(:delete)   { client.delete 'http://example.com' }
      let(:failure_boby) { '<?xml version="1.0" encoding="UTF-8"?><result code="The url or md5 could not be found."/>' }

      it 'adds "Authorization: Bearer my-access-token" header' do
        delete
        expect(WebMock).to have_requested(:post, endpoint)
          .with(headers: { 'Authorization' => 'Bearer my-access-token' })
      end

      it 'sends url=http://example.com' do
        delete
        expect(WebMock).to have_requested(:post, endpoint).with { |r| assert_param(r, 'url', 'http://example.com') }
      end

      context 'existing URL' do
        it 'returns true' do
          expect(delete).to eq true
        end
      end

      context 'non-existing URL' do
        let(:result) { :failure }

        it 'return false' do
          expect(delete).to eq false
        end
      end

      after { remove_request_stub @request }
    end
  end
end
