# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#=require hmac-sha256

root = exports ? this

do ($=jQuery) ->
  $ ->
    class AWS4Authorization
      constructor: (@name) ->
        @algorithm = 'AWS4-HMAC-SHA256'

      apply: (obj, authorizations) ->
        @password = $('#input_apiPassword')[0].value
        @access_key_id = $('#input_apiUser')[0].value

        @datetime = @dateStamp()
        @region = 'europe'
        @url = new URL(obj.url)
        @service = @url.hostname.split('.',2)[0]
        @pathname = @url.pathname
        @search = @query_sorted(@url.searchParams.toString())
        @method = obj.method.toUpperCase()
        @req_headers = $.extend({}, obj.headers)
        @body = obj.body ? ''

        @req_headers['X-Amz-Date'] = @datetime

        obj.headers["Authorization"] = @authorization()
        obj.headers['X-Amz-Date'] = @datetime
        obj.headers['X-Amz-Algorithm'] = @algorithm
        obj.headers['X-Amz-SignedHeaders'] =  @signed_headers()

        console.log "String to sign #{@string_to_sign()}"
        console.log "Canonical string #{@canonical_string()}"

        hash = @signature_key(@password, @datetime, @region, @service)

        console.log 'key: ' + hash.toString(CryptoJS.enc.Hex)


      authorization:  ->
        parts = []
        cred_string = @credential_string(@datetime)
        parts.push(@algorithm + ' Credential=' +
                   @access_key_id + '/' + cred_string);
        parts.push('SignedHeaders=' + @signed_headers())
        parts.push('Signature=' + @signature())

        parts.join(', ')

      signature: ->
        hash = @signature_key(@password, @datetime, @region, @service)
        hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, hash)
        hmac.update @string_to_sign()

        hash= hmac.finalize()
        # hash = CryptoJS.HmacSHA256(@string_to_sign(), key)
        hash.toString(CryptoJS.enc.Hex)

      string_to_sign: () ->
        parts = []
        parts.push('AWS4-HMAC-SHA256')
        parts.push(@datetime)
        parts.push(@credential_string())
        parts.push(@hex_encoded_hash(@canonical_string()))
        parts.join('\n')

      credential_string: () ->
        parts = []
        parts.push(@datetime.substr(0, 8))
        parts.push(@region)
        parts.push(@service)
        parts.push('aws4_request')
        parts.join('/')

      canonical_string: ->
        parts = []

        req_headers = @req_headers

        parts.push(@method)
        parts.push(@pathname)
        parts.push(@search)
        parts.push(@canonical_headers() + '\n')
        parts.push(@signed_headers())
        parts.push(@hex_encoded_body_hash())
        parts.join('\n')

      canonical_headers: () ->
        headers = []
        for header, item of @req_headers
          header = header.toLowerCase()

          if @is_signable_header(header)
            item = @canonical_header_values(item.toString())
            headers.push(header + ':' + item)

        headers.sort((a, b) ->
          if (a.toLowerCase() < b.toLowerCase()) == true
            -1
          else
             1
        )

        headers.join('\n')

      query_sorted: (query_str) ->
        queries = query_str.split('&')

        queries.sort((a, b) ->
          if (a.toLowerCase() < b.toLowerCase()) == true
            -1
          else
            1
        )

        queries.join('&')


      canonical_header_values: (value) ->
        value.replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '')

      hex_encoded_body_hash: ->
        @hex_encoded_hash(@body)

      hex_encoded_hash: (msg)->
            hash = CryptoJS.SHA256(msg)
            hash.toString(CryptoJS.enc.Hex)

      signed_headers: ()->
        keys = []
        for header, item of @req_headers
          header = header.toLowerCase()
          if @is_signable_header(header)
            keys.push(header)

        keys.sort().join(';')

      is_signable_header: (header)->
        not_signable_headers = ['authorization', 'content-length', 'content-type' ,'user-agent']
        not_signable_headers.indexOf(header) < 0

      dateStamp: ->
         (new Date()).toISOString().replace(/[:\-]|\.\d{3}/g, '')

      signature_key: (key, dateStamp, regionName, serviceName) ->
        dateStamp = dateStamp.substr(0, 8)
        keyWords = CryptoJS.enc.Utf8.parse("AWS4" + key)

        hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, keyWords)
        hmac.update dateStamp
        hash= hmac.finalize()

        console.log "Date: #{dateStamp} #{hash.toString(CryptoJS.enc.Hex)}"

        hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, hash)
        hmac.update regionName
        hash= hmac.finalize()

        console.log "Region: #{regionName} #{hash.toString(CryptoJS.enc.Hex)}"

        hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, hash)
        hmac.update serviceName
        hash= hmac.finalize()

        console.log "Service: #{serviceName} #{hash.toString(CryptoJS.enc.Hex)}"

        hmac = CryptoJS.algo.HMAC.create(CryptoJS.algo.SHA256, hash)
        hmac.update "aws4_request"

        hmac.finalize()


    root.authorizations.add("aws4_authorization", new AWS4Authorization("aws4_authorization"))
