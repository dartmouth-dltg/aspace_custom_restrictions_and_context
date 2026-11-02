class CustomRestrictionsInfiniteTree extends CustomRestrictionsTreeBase {

  constructor(repoUri, appVersion = 4.0) {
    super(repoUri, appVersion);
  }

  fullConfig() {
    let rootNodeSelector = 'root-row';
    let decoratorSelector = 'a.record-title';
    let nodeSelectorClass = 'largetree-node';
    if (this.appVersion >= 4.1) {
      rootNodeSelector = 'root.node';
      decoratorSelector = 'a.node-title';
      nodeSelectorClass = 'node';
    }
    const infiniteTreeCfg = {
      infiniteTree: true,
      treeSelector: 'tree-container',
      nodeSelectorClass: nodeSelectorClass,
      rootNodeSelector: rootNodeSelector,
      decoratorNodeSelector: decoratorSelector,
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    // 5.0: show pages mount a record-linked tree (id 'record-tree-container') and keep no
    // global; the infinite view uses #infinite-tree-container. Find it by class.
    const container = document.querySelector('.infinite-tree-container');
    if (container) {
      if (!container.id) container.id = 'custom-restrictions-tree-container';
      infiniteTreeCfg.treeSelector = container.id;
    }

    return {...cfg, ...infiniteTreeCfg};
  }
}
