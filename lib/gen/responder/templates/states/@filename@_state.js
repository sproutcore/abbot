<%= copyright_block("#{namespace}.#{class_name.upcase}") %>
/*globals <%= namespace %> */

/** @class

  (Document Your State Here)

  @extends <%= base_class_name || 'SC.Responder' %>
  @version 0.1
*/
<%= namespace %>.<%= class_name.upcase %> = <%= base_class_name || 'SC.Responder' %>.create(
/** @scope <%= namespace %>.<%= class_name.upcase %>.prototype */ {

  /**
    The next state to check if this state does not implement the action.
  */
  nextResponder: null,
  
  didBecomeFirstResponder: function() {
    // Called when this state becomes first responder
  },
  
  willLoseFirstResponder: function() {
    // Called when this state loses first responder
  },
  
  // ..........................................................
  // EVENTS
  //
  
  // add event handlers here
  someAction: function() {
    
  }
  
}) ;
