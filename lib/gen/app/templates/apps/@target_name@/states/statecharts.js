<%= namespace %>.statechart = SC.Statechart.create({

  initialState: 'rootState',

  rootState: SC.State.extend({

    initialSubstate:'MainPageState',
    
    MainPageState: SC.State.plugin('<%= namespace %>.MainPageState'),
  })

});