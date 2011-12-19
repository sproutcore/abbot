<%= namespace %>.statechart = SC.Statechart.create({

  initialState: 'rootState',

  rootState: SC.State.extend({

    initialSubstate:'ReadyState',
    
    ReadyState: SC.State.plugin('<%= namespace %>.ReadyState'),
    // SomeOtherState: SC.State.plugin('<%= namespace %>.SomeOtherState')
  })

});