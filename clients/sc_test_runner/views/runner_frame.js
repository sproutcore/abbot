// ==========================================================================
// TestRunner.RunnerFrameView
// ==========================================================================

require('core');

TestRunner.TEST_NONE    = 'none' ;
TestRunner.TEST_LOADING = 'loading' ;
TestRunner.TEST_RUNNING = 'running' ;
TestRunner.TEST_PASSED  = 'passed'  ;
TestRunner.TEST_FAILED  = 'failed'  ;

TestRunner.RunnerFrameView = SC.View.extend({
  
  // This is set to the test you want to run.
  test: null,
  
  // This will automatically change to reflect the current load state.
  state: TestRunner.TEST_NONE,

  // when the test changes, set the URL of the iframe 
  testObserver: function() {
    var test = this.get('test') ;
    var url = (test) ? test.get('url') : '' ;
    
    // make sure we clear out the old document settings if needed.
    var doc = (this.rootElement.contentWindow) ? this.rootElement.contentWindow.document : this.rootElement.document ;
    if (doc) doc.testExpired = YES ;
    
    // if the document URL is already loaded, then reload it...
    if (url == this.rootElement.src) {
      this.rootElement.src = 'javascript:;' ;
      this.rootElement.src = url ;
      // if (doc && doc.location) doc.location.reload() ;
      
    // otherwise set to the new URL.
    } else {
      this.rootElement.src = url ;
    }
    
    this.set('state', TestRunner.TEST_LOADING) ;
    this.checkState() ;
  }.observes('test'),
  
  // this can be called periodically to update the current test state,
  // possibly rescheduling itself.
  checkState: function() {
    var doc = (this.rootElement.contentWindow) ? this.rootElement.contentWindow.document : this.rootElement.document ;
    
    var queuedTests = (doc) ? doc.queuedTests : null ;
    var testStatus = (doc) ? doc.testStatus : null ;
    var status = TestRunner.TEST_NONE ;
    var reschedule = true ;
    
    if (!doc || (queuedTests == null) || doc.testExpired) {
      status = (this.get('test')) ? TestRunner.TEST_LOADING : TestRunner.TEST_NONE;
      
    // tests have finished running.
    } else if (queuedTests == 0) {
      status = (testStatus != 'SUCCESS') ? TestRunner.TEST_FAILED : TestRunner.TEST_PASSED ;
      reschedule = false ;
      
    // test still need to run?
    } else {
      status = ((testStatus != 'FAILED') && (testStatus != 'ERROR')) ? TestRunner.TEST_RUNNING : TestRunner.TEST_FAILED ;
      if (status == TestRunner.TEST_FAILED) reschedule = false ;
    }
    
    if (this.get('state') != status) this.set('state', status) ;
    if (reschedule) this.invokeLater(this.checkState,100) ;
    
  }
  
}) ;
