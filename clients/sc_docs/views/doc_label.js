// ==========================================================================
// Docs.DocLabelView
// ==========================================================================

require('core');

Docs.DocLabelView = SC.ButtonView.extend({
  
  emptyElement: '<a href="javascript:;"><span></span></a>',

  contentObserver: function() {
    var c = this.get('content') ;
    this.set('labelText', (c) ? c.get('title') : '(NONE)') ;
  }.observes('content'),
  
  labelSelector: 'span',
  
  mouseDown: function() { return false; }
  
}) ;
