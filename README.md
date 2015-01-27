# Angular Cache Proxy

Store and retrieve API responses in local storage

## Installation

Add angular-cache-proxy to your .bower.json and bower install

## Usage

TODO: Write usage instructions

### Dependencies

* [angular-local-storage]:https://github.com/grevory/angular-local-storage
* [Restangular]:https://github.com/mgonto/restangular

## License

MIT

### Todo's

 - Break out into RestangularCacheProxy and HttpCacheProxy, using CacheProxy base class

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
