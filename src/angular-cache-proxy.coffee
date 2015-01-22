# Angular Cache Proxy for AngularJS - Store and retrieve API responses in local storage
# @version v0.0.1 - 2015-01-21
# @link http://github.com/learnist/angular-cache-proxy
# @author Buck DeFore <julien@revolunet.com>
# @license MIT License, http://www.opensource.org/licenses/MIT

module = angular.module 'angular-cache-proxy', [
  'LocalStorageModule',
  'restangular'
]

module.provider 'CacheProxy', ->

  configurables =

    # With verifyCache set to false, if data at uniqueIdentifier exists in local storage
    # then we do not call the API for the latest version to verify that the local is up to date
    verifyCache: true

    # Prepending to all $http calls. If using Restangular, use
    # RestangularProvider.setBaseUrl(<baseUrl>) in your app.config
    baseUrl: ""

    # Keys which either change too frequently or are not important enough to trigger
    # a reload of the page should they not match values in cache
    unimportantKeys: []

    # When to consider a cached version stale and re-request from server, in milliseconds
    expiry: 1000 * 60 * 60 * 24 * 7 # one week

    # A callback to fire every time cache does not match the latest from the API
    cacheInvalidCallback: null

  @configure = (overrides) ->
    angular.extend configurables, overrides

  @$get = ($q, $timeout, $http, Restangular, localStorageService) ->

    class CacheProxy

      getCache = (uniqueIdentifier) ->
        cacheObj = localStorageService.get uniqueIdentifier
        return undefined if !cacheObj?
        if Date.now() > cacheObj.timestamp + configurables.expiry
          console.log "Cache for #{uniqueIdentifier} older than expiry, ignoring"
          return undefined
        cacheObj.json

      setCache = (key, value) ->
        cacheObj =
          json: value
          timestamp: Date.now()
        localStorageService.set key, cacheObj

      validate = (oldVersion, newVersion) ->
        if newVersion.updatedAt?
          # such as board data, we don't care if views have incremented
          oldVersion.updatedAt == newVersion.updatedAt
        else
          # such as /categories/0?extraFields=promoted
          pruneUnimportantData version for version in [newVersion, oldVersion]

          JSON.stringify(oldVersion) == JSON.stringify(newVersion)

      pruneUnimportantData = (obj) ->
        for key, data of obj
          for keyToMatch in configurables.unimportantKeys
            delete obj[keyToMatch]
          pruneUnimportantData(data) if typeof(data) is "object"

      getCacheAndRequest = (uniqueIdentifier, requestFn) ->
        $q (resolve, reject) =>
          cachedResponse = getCache(uniqueIdentifier)

          # Resolve promise with cached version if there, but on next tick to simulate asynchronous behavior
          $timeout =>
            resolve(cachedResponse) if cachedResponse?
          , 0

          # Then fetch from backend and notify if mismatch
          if configurables.verifyCache or !cachedResponse?
            makeRequest(uniqueIdentifier, requestFn).then (results) ->
              resolve results

      makeRequest = (uniqueIdentifier, requestFn) ->
        $q (resolve, reject) =>
          # timeout because ui router will withhold full resolution if http requests are outgoing (why?!)
          $timeout =>
            requestFn().then (response) =>

              response = Restangular.stripRestangular response

              # $http would return a response object, convenience check here to
              # unify with returning the data (a la Restangular)
              response = response.data if response.data?

              cached = getCache(uniqueIdentifier)
              setCache uniqueIdentifier, response

              if !cached?
                resolve response
              else if !validate(cached, response) && configurables.cacheInvalidCallback?
                configurables.cacheInvalidCallback(response)
          , 0

      @paramsObjectToString: (params) ->
        output = ""
        output += "&#{key}=#{value}" for key, value of params
        "?" + output.substr(1)

      @one: (model, id, params) ->
        uniqueIdentifier = "#{configurables.baseUrl}/#{model}/#{id}"
        uniqueIdentifier += @paramsObjectToString(params) if params?
        requestFn = (-> Restangular.one(model, id).get(params))
        getCacheAndRequest(uniqueIdentifier, requestFn)

      @list: (model, id, params) ->
        if typeof params is "object"
          params = @paramsObjectToString params
        uniqueIdentifier = "#{configurables.baseUrl}/#{model}"
        uniqueIdentifier += "/#{id}" if id?
        uniqueIdentifier += "/#{params}" if params?
        requestFn = (-> Restangular.one(model, id).getList(params))
        getCacheAndRequest(uniqueIdentifier, requestFn)

      @get: (url, params) ->
        if typeof params is "object"
          params = @paramsObjectToString params
        url += params if params?
        url = "#{configurables.baseUrl}/#{url}" if configurables.baseUrl?
        uniqueIdentifier = url
        requestFn = (-> $http.get(url))
        getCacheAndRequest(uniqueIdentifier, requestFn)

      @store: (id, obj) ->
        setCache "#{configurables.baseUrl}/#{id}", obj

      @onCacheInvalid: (callback) ->
        configurables.cacheInvalidCallback = callback

      new CacheProxy()

  null
