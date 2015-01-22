describe 'CacheProxy', ->

  $httpBackend = $window = $rootScope = $timeout = localStorageService =
  CacheProxy = mockLocalStorageService = Board =
  staleBoard = freshBoard = mockwindow = undefined

  beforeEach module 'learnist', ($provide) ->
    localStorage = {}

    staleBoard = { updatedAt: 1234, cached: true }
    freshBoard = { updatedAt: 1235 }

    mockLocalStorageService =
      get: (key) ->
        localStorage[key]
      set: (key, value) ->
        localStorage[key] = value
      clearAll: () ->
        localStorage = {}

    $provide.value 'localStorageService', mockLocalStorageService

    # [AKA] Because coffeescript will return the last value:
    # See https://gist.github.com/jbrowning/9527280
    return

  beforeEach inject (_Board_, _$window_, _$httpBackend_, _$rootScope_, _$timeout_, _localStorageService_, _CacheProxy_) ->
    Board = _Board_
    $window = _$window_
    $httpBackend = _$httpBackend_
    $rootScope = _$rootScope_
    $timeout = _$timeout_
    CacheProxy = _CacheProxy_
    localStorageService = _localStorageService_

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  flushTimeoutAndHttpBackend = ->
    $timeout.flush()
    $httpBackend.flush()

  describe '@one', ->

    describe 'when local storage has a version at the key provided, cached one day previously', ->

      beforeEach ->
        oneDay = 1000 * 60 * 60 * 24
        localStorageService.set '/v3/boards/4', { json: staleBoard, timestamp: Date.now() - oneDay }

      it 'resolves a promise with data from the cache, and makes a separate http request', ->
        responseBoard = { updatedAt: staleBoard.updatedAt, cached: false }
        $httpBackend.when("GET", /boards\/4.*/).respond(responseBoard)
        CacheProxy.one('boards', 4).then (response) ->
          expect(response.updatedAt).toBe(staleBoard.updatedAt)
          expect(response.cached).toBe(true)
        flushTimeoutAndHttpBackend()

    describe 'when local storage has a cached version older than the expiry limit', ->

      beforeEach ->
        twelveDays = 1000 * 60 * 60 * 24 * 12
        localStorageService.set '/v3/boards/4', { json: staleBoard, timestamp: Date.now() - twelveDays }

      it 'makes an http request for the data and resolves with fresh data', ->
        responseBoard = { updatedAt: freshBoard.updatedAt, cached: false }
        $httpBackend.when("GET", /boards\/4.*/).respond(responseBoard)
        CacheProxy.one('boards', 4).then (response) ->
          expect(response.updatedAt).toBe(freshBoard.updatedAt)
        flushTimeoutAndHttpBackend()

    describe 'when local storage has no data at the key provided', ->

      it 'resolves a promise with up to date board', ->
        $httpBackend.when("GET", /boards\/4.*/).respond(freshBoard)
        CacheProxy.one('boards', 4).then (response) ->
          expect(response.updatedAt).toBe(freshBoard.updatedAt)
        flushTimeoutAndHttpBackend()

  describe '@get', ->
    it 'resolves a promise with the data itself and not a response object', ->
      $httpBackend.when("GET", /boards\/4.*/).respond(freshBoard)
      CacheProxy.get('boards/4').then (response) ->
        expect(response.data).toBeUndefined()
        expect(response.updatedAt).toBe(freshBoard.updatedAt)
      flushTimeoutAndHttpBackend()
