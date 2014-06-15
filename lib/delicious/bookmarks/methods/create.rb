require 'active_support/concern'

module Delicious
  module Bookmarks
    module Methods

      module Create
        extend ActiveSupport::Concern

        # Create new bookmark
        #
        # @example
        #   client.bookmarks.create url: 'http://example.com',
        #                           description: 'Example website',
        #                           extended: 'Extended information',
        #                           tags: %w(tag1 tag2),
        #                           dt: '2014-04-15T10:20:00Z',
        #                           shared: true,
        #                           replace: false
        #
        # @param attrs [Hash] Bookmark attributes
        # @return [Post]
        def create(attrs)
          post = Delicious::Post.new url:         attrs[:url],
                                     description: attrs[:description],
                                     extended:    attrs[:extended],
                                     tags:        attrs[:tags],
                                     dt:          attrs[:dt],
                                     shared:      attrs[:shared]

          if post.valid?
            response = @client.connection.post '/v1/posts/add', post_attrs(post, attrs[:replace])
            code = response.body['result']['code']
            throw code unless 'done' == code
            post.persisted = true
            post.delicious_client = @client
          end

          post
        end

        private

        def post_attrs(post, replace = false)
          { url:         post.url,
            description: post.description,
            extended:    post.extended,
            tags:        post.tags.join(','),
            dt:          post.dt,
            shared:      post.shared ? 'yes' : 'no',
            replace:     replace ? 'yes' : 'no' }
        end
      end

    end
  end
end