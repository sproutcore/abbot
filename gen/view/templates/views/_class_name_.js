// ==========================================================================
<<<<<<< HEAD:gen/view/templates/views/_class_name_.js
// <%= @class_name %>
=======
// <%= class_name %>
// copyright ©<%= Time.now.year %> My Company, Inc.
>>>>>>> Make templates fit new SC app structure:gen/controller/templates/controllers/_subclass_name_.js
// ==========================================================================

require('core');

/** @class

  (Document Your View Here)

  @extends <%= base_class_name 'SC.Object' %>
  @author AuthorName
  @static
*/
<<<<<<< HEAD:gen/view/templates/views/_class_name_.js
<%= @class_name %> = <%= base_class_name 'SC.Object' %>.create(
/** @scope <%= @class_name %> */ {
=======
<%= class_name %> = <%= base_class_name 'SC.Object' %>.create(
/** @scope <%= class_name %>.prototype */ {
>>>>>>> Make templates fit new SC app structure:gen/controller/templates/controllers/_subclass_name_.js

  // TODO: Add your own code here.

}) ;
