<%= copyright_block(namespace_instance_name) %>
/*globals <%= namespace %> */

/** @class

  (Document Your Controller Here)

  @extends <%= base_class_name || 'SC.Object' %>
*/
<%= namespace_instance_name %> = <%= base_class_name || 'SC.ObjectController' %>.create(
/** @scope <%= namespace_instance_name %>.prototype */ {

  // TODO: Add your own code here.

}) ;
