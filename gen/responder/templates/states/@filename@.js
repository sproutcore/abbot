// ==========================================================================
// Project:   <%= namespace_class_name %>
// Copyright: ©<%= Time.now.year %> My Company, Inc.
// ==========================================================================
/*globals <%= namespace %> */

/** @class

  (Document Your State Here)

  @extends <%= base_class_name || 'SC.Responder' %>
*/
<%= namespace_class_name %> = <%= base_class_name || 'SC.Responder' %>.extend(
/** @scope <%= namespace_class_name %>.prototype */ {
  /**
    The next state to check if this state does not implement the action.
  */
  nextResponder: null,
  
  // ..........................................................
  // EVENTS
  //
  didBecomeFirstResponder: function() {
    // Called when this state becomes first responder
  },
  
  willLoseFirstResponder: function() {
    //Called when this state loses first responder
  }
}) ;
