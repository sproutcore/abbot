// ==========================================================================
// TestRunner.Test
// ==========================================================================

require('core');

TestRunner.Test = SC.Record.extend({
  
  // TODO: Add your own code here.
  title: function() {
    return this.get('name').replace(/\.rhtml$/,'');
  }.property('name')
  
}) ;
