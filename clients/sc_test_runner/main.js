// ==========================================================================
// TestRunner
// ==========================================================================

function main() {
  //TestRunner.server.preload(TestRunner.FIXTURES) ;
  SC.page.awake() ;
  //TestRunner.runnerController.reloadTests() ;

  console.log('main') ;
  var indexRoot = window.location.pathname.toString().replace(/-tests\/.*/,'-tests').substr(1,window.location.pathname.length);
  var clientName = indexRoot.match(/([^\/]+)\/-tests/)[1];
  var urlRoot = indexRoot.replace(new RegExp("^%@/?".fmt(window.indexPrefix)), window.urlPrefix + '/');
  console.log('indexRoot: %@ clientName: %@ urlRoot: %@'.fmt( indexRoot, clientName, urlRoot));

  TestRunner.runnerController.set('selection',[]) ;
  TestRunner.runnerController.set('urlRoot', urlRoot) ;
  TestRunner.runnerController.set('indexRoot', indexRoot) ;
  TestRunner.runnerController.set('clientName', clientName) ;
  TestRunner.runnerController.reloadTests() ;
} ;
