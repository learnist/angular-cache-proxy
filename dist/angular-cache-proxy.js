var module;

module = angular.module('angular-cache-proxy', ['LocalStorageModule', 'restangular']);

module.provider('CacheProxy', function() {
  var configurables;
  configurables = {
    verifyCache: true,
    baseUrl: "",
    unimportantKeys: [],
    expiry: 1000 * 60 * 60 * 24 * 7,
    cacheInvalidCallback: null
  };
  this.configure = function(overrides) {
    return angular.extend(configurables, overrides);
  };
  this.$get = function($q, $timeout, $http, Restangular, localStorageService) {
    var CacheProxy;
    return CacheProxy = (function() {
      var getCache, getCacheAndRequest, makeRequest, pruneUnimportantData, setCache, validate;

      function CacheProxy() {}

      getCache = function(uniqueIdentifier) {
        var cacheObj;
        cacheObj = localStorageService.get(uniqueIdentifier);
        if (cacheObj == null) {
          return void 0;
        }
        if (Date.now() > cacheObj.timestamp + configurables.expiry) {
          console.log("Cache for " + uniqueIdentifier + " older than expiry, ignoring");
          return void 0;
        }
        return cacheObj.json;
      };

      setCache = function(key, value) {
        var cacheObj;
        cacheObj = {
          json: value,
          timestamp: Date.now()
        };
        return localStorageService.set(key, cacheObj);
      };

      validate = function(oldVersion, newVersion) {
        var version, _i, _len, _ref;
        if (newVersion.updatedAt != null) {
          return oldVersion.updatedAt === newVersion.updatedAt;
        } else {
          _ref = [newVersion, oldVersion];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            version = _ref[_i];
            pruneUnimportantData(version);
          }
          return JSON.stringify(oldVersion) === JSON.stringify(newVersion);
        }
      };

      pruneUnimportantData = function(obj) {
        var data, key, keyToMatch, _i, _len, _ref, _results;
        _results = [];
        for (key in obj) {
          data = obj[key];
          _ref = configurables.unimportantKeys;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            keyToMatch = _ref[_i];
            delete obj[keyToMatch];
          }
          if (typeof data === "object") {
            _results.push(pruneUnimportantData(data));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      getCacheAndRequest = function(uniqueIdentifier, requestFn) {
        return $q((function(_this) {
          return function(resolve, reject) {
            var cachedResponse;
            cachedResponse = getCache(uniqueIdentifier);
            $timeout(function() {
              if (cachedResponse != null) {
                return resolve(cachedResponse);
              }
            }, 0);
            if (configurables.verifyCache || (cachedResponse == null)) {
              return makeRequest(uniqueIdentifier, requestFn).then(function(results) {
                return resolve(results);
              });
            }
          };
        })(this));
      };

      makeRequest = function(uniqueIdentifier, requestFn) {
        return $q((function(_this) {
          return function(resolve, reject) {
            return $timeout(function() {
              return requestFn().then(function(response) {
                var cached;
                response = Restangular.stripRestangular(response);
                if (response.data != null) {
                  response = response.data;
                }
                cached = getCache(uniqueIdentifier);
                setCache(uniqueIdentifier, response);
                if (cached == null) {
                  return resolve(response);
                } else if (!validate(cached, response) && (configurables.cacheInvalidCallback != null)) {
                  return configurables.cacheInvalidCallback(response);
                }
              });
            }, 0);
          };
        })(this));
      };

      CacheProxy.paramsObjectToString = function(params) {
        var key, output, value;
        output = "";
        for (key in params) {
          value = params[key];
          output += "&" + key + "=" + value;
        }
        return "?" + output.substr(1);
      };

      CacheProxy.one = function(model, id, params) {
        var requestFn, uniqueIdentifier;
        uniqueIdentifier = "" + configurables.baseUrl + "/" + model + "/" + id;
        if (params != null) {
          uniqueIdentifier += this.paramsObjectToString(params);
        }
        requestFn = (function() {
          return Restangular.one(model, id).get(params);
        });
        return getCacheAndRequest(uniqueIdentifier, requestFn);
      };

      CacheProxy.list = function(model, id, params) {
        var requestFn, uniqueIdentifier;
        if (typeof params === "object") {
          params = this.paramsObjectToString(params);
        }
        uniqueIdentifier = "" + configurables.baseUrl + "/" + model;
        if (id != null) {
          uniqueIdentifier += "/" + id;
        }
        if (params != null) {
          uniqueIdentifier += "/" + params;
        }
        requestFn = (function() {
          return Restangular.one(model, id).getList(params);
        });
        return getCacheAndRequest(uniqueIdentifier, requestFn);
      };

      CacheProxy.get = function(url, params) {
        var requestFn, uniqueIdentifier;
        if (typeof params === "object") {
          params = this.paramsObjectToString(params);
        }
        if (params != null) {
          url += params;
        }
        if (configurables.baseUrl != null) {
          url = "" + configurables.baseUrl + "/" + url;
        }
        uniqueIdentifier = url;
        requestFn = (function() {
          return $http.get(url);
        });
        return getCacheAndRequest(uniqueIdentifier, requestFn);
      };

      CacheProxy.store = function(id, obj) {
        return setCache("" + configurables.baseUrl + "/" + id, obj);
      };

      CacheProxy.onCacheInvalid = function(callback) {
        return configurables.cacheInvalidCallback = callback;
      };

      new CacheProxy();

      return CacheProxy;

    })();
  };
  return null;
});
