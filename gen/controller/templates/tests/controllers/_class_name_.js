<%% # ========================================================================
   # <%= @class_name %> Unit Test
   # ========================================================================
%>
<script>

Test.context("<%= @class_name %>",{

  "TODO: Add your own tests here": function() {
    true.shouldEqual(true) ;
  }

}) ;

if (window.main && (appMain = main)) main = null ;

</script>