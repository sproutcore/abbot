// ==========================================================================
// TestRunner.runnerController
// ==========================================================================

require('core');

TestRunner.runnerController = SC.Object.create({

  // This is used in the client warning dialog.
  windowLocation: window.location.href,
  
  // This is the current client name.
  clientName: '',
  
  // This is displayed as the main UI label.
  displayClientName: function() {
    var clientName = (this.get('clientName') || '').humanize().capitalize();
    if (clientName == 'Sproutcore') clientName = 'SproutCore' ; 
    return "%@ Tests".fmt(clientName) ;
  }.property('clientName'),
  
  arrangedObjects: [],
  selection: [],

  selectedTest: function() {
    var sel = this.get('selection') ;
    return (sel && sel.length > 0) ? sel[0] : null ;
  }.property('selection'),

  testState: null,

  testStateLabel: function() {
    switch(this.get('testState')) {
      case TestRunner.TEST_LOADING:
        return 'Loading Test...' ;
        
      case TestRunner.TEST_RUNNING:
        return 'Test Running...' ;
        
      case TestRunner.TEST_PASSED:
        return 'Passed!' ;
        
      case TestRunner.TEST_FAILED:
        return 'Failed.' ;
        
      default:
        return '' ;
    }
  }.property('testState'),

  testStateIsRunning: function() {
    return (this.get('testState') === TestRunner.TEST_RUNNING) ;
  }.property('testState'),
  
  isRunning: NO,
  isContinuousIntegrationEnabled: NO,
  
  runTestLabel: function() {
    return (this.get('isRunning')) ? "Stop All Tests" : "Run All Tests" ;
  }.property('isRunning'),
  
  toggleRunTests: function() {
    this.toggleProperty('isRunning') ;
  },
  
  rerunCurrentTest: function() {
    var test = this.get('selectedTest') ;
    if (test) {
      this.set('selection', []) ;
      this.set('selection', [test]) ;
    }
  },
  
  canRerunCurrentTest: function() {
    if (this.get('isRunning')) return NO ;
    var state = this.get('testState') ;
    var ret = (state === TestRunner.TEST_FAILED || state === TestRunner.TEST_PASSED) ? YES : NO ;
    return ret; 
  }.property('isRunning', 'testState'),
  
  reloadTests: function() {
    
    // Use Ajax to ask the server for the latest set of tests for the 
    // current client.
    var urlRoot = this.get('urlRoot') ;
    TestRunner.server.request(urlRoot, 'index.js', null, {
      onSuccess: this._reloadSuccess.bind(this),
      onFailure: this._reloadFailure.bind(this)
    }) ;
  },
  
  _reloadSuccess: function(status, transport) {
    var json = transport.responseText ;
    var records = eval(json) ;
    if ($type(records) != T_ARRAY) {
      return this._reloadFailure(status, transport) ;
    }

    // update the list of tests from the server.  The return value will be
    // the records included in the list.  This is what will become our new
    // list.
    var recs = SC.Store.updateRecords(records, this, TestRunner.Test, true);
    
    // show warning panel if the records are empty.  Also reload tests
    // periodically so that when the user resolves the problem, we can start
    // working away immediately.
    if (recs.length == 0) {
      SC.page.get('noTestsPanel').set('isVisible',true) ;
      this.invokeLater(this.reloadTests,2000) ; 
    } else {
      SC.page.get('noTestsPanel').set('isVisible',false) ;
    }
    
    // sort the records by name and set as the new arrangedObjects.
    recs = recs.sort(function(a,b) {
      var a_g = a.get('group') || '';
      var b_g = b.get('group') || '';
      
      var ret = a_g.localeCompare(b_g) ;
      return (ret != 0) ? ret : (a.get('title') || '').localeCompare(b.get('title') || '') ;
    }) ;
    
    var hadArrangedObjects = this.get('arrangedObjects').length > 0 ;
    this.set('arrangedObjects', recs) ;
    
    // if the current selection is not in the list, clear the selection.
    var test = this.get('selectedTest') ;
    if (test && !(recs.include(test))) this.set('selection', []) ;
    
    // if continuous integration is turned on and we are running, restart
    // the tests immediately. or if we did not have arranged objects.
    if (!hadArrangedObjects || (this.get('isRunning') && (this.get('isContinuousIntegrationEnabled')))) {
      if (recs.length >0) this.set('selection',[recs.first()]) ;
    }
  },
  
  _reloadFailure: function(status, transport) {
    console.log('TEST RELOAD FAILED!') ;
  },
  
  // whenever isRunning changes to YES, select the first test.
  isRunningObserver: function() {
    if (this.didChangeFor('isRunningObserver', 'isRunning')) {
      if (this.get('isRunning')) {
        var tests = this.get('arrangedObjects') ;
        var firstTest = (tests && tests.length > 0) ? [tests[0]] : [] ;
        this.set('selection', []) ; // clear selection.
        var t = function() {
          this.set('selection', firstTest) ;
        }.invokeLater(this,1) ;
      }
    }
  }.observes('isRunning'),
  
  // whenever the testState changes, then go on to the next test, if
  // running.
  testStateObserver: function() {
    if (!this.didChangeFor('testStateObserver', 'testState')) return ;
    if (!this.get('isRunning')) return ;
    
    var testState = this.get('testState') ;
    
    // If test passed, go onto the next test.
    if (testState == TestRunner.TEST_PASSED) {
      var tests = this.get('arrangedObjects') || [];
      var test = this.get('selectedTest') || tests.first();
      
      // find the idx of the next item.
      var idx = tests.indexOf(test) ;
      if (idx < 0) idx = 0 ;
      idx++ ;
      
      // if the idx is at the end of the set of tests, go back to the 
      // beginning only if continuous integration is enabled.
      if (idx >= tests.length) {
        if (this.get('isContinuousIntegrationEnabled')) {
          this.reloadTests() ;
        } else {
          this.set('isRunning', false) ;
        }
        return ;
      }
      
      // now load the next test.
      test = tests[idx] ;
      if (!test) test = tests[0] ;
      this.set('selection', (test) ? [test] : []) ;

    // if the test failed, then stop running the tests and throw an alert
    // if continuous integration is on.
    } else if (testState == TestRunner.TEST_FAILED) {
      this.set('isRunning', false) ;
      if (this.get('isContinuousIntegrationEnabled') == YES) {
        alert('Unit Test Failed!') ;
      }
    }
  }.observes('testState')
}) ;
