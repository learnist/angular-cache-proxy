# Angular Cache Proxy

Speed up the render time of your site by using locally stored copies of API responses. Replace calls to $http or Restangular with CacheProxy. Promises will be resolved with local versions, then will be kept up-to-date with an API request in the background.

## Installation

Add angular-cache-proxy to your .bower.json and bower install

## API

* one(model, id, params) - Analogous to $http.get
* list(model, id, params) - Analogous to calling getList() on a Restangular resource
* get(model, id, params) - Analogous to calling get() on a Restangular resource
* store(id, obj) - Manually store data
* onCacheInvalid(callback) - Will execute callback function whenever server response invalidates local storage cache. Useful for indicating to the user that they may have stale content.

Explanation of parameters:

* model - A string representing the model being requested
* id - A string representing the ID of the model requested
* params - An object with key value pairs of additional params to send along with request

## Configuration

* verifyCache - With verifyCache set to false, if data at uniqueIdentifier exists in local storage then we do not call the API for the latest version to verify that the local is up to date (default: true)

* baseUrl - Prepending to all $http calls. If using Restangular, use RestangularProvider.setBaseUrl(<baseUrl>) in your app.config (default: "")

* unimportantKeys - Keys which either change too frequently or are not important enough to trigger a reload of the page should they not match values in cache (default: [])

* expiry - When to consider a cached version stale and re-request from server, in milliseconds (default: 1000 * 60 * 60 * 24 * 7 # one week)

* cacheInvalidCallback - A callback to fire every time cache does not match the latest from the API (default: null)

* versionTag - The identifier for the header response that declares API version. Local storage will be cleared if this version is different than what was previously heard (default: 'versiontag')

## Dependencies

* [angular-local-storage](https://github.com/grevory/angular-local-storage)
* [Restangular](https://github.com/mgonto/restangular)

## License

MIT

### Todo

* Break out into RestangularCacheProxy and HttpCacheProxy, using CacheProxy base class

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

While developing, here's how you can watch the coffee file to automatically update the JavaScript output:
```
coffee --watch --bare --output dist --compile src
```
or
```
coffee --watch --bare --output $YOUR_APPS_BOWER_COMPONENTS/angular-local-cache/dist --compile src
```
