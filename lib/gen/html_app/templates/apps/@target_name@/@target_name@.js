// ==========================================================================
// Project:   <%= namespace %>
// Copyright: ©<%= Time.now.year %> My Company, Inc.
// ==========================================================================
/*globals <%= namespace %> */

<%= namespace %> = SC.Application.create();

jQuery(document).ready(function() {
  Todos.mainPane = SC.TemplatePane.append({
    layerId: '<%= target_name %>',
    templateName: '<%= target_name %>'
  });
});
