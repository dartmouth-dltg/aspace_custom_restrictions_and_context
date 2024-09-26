class CustomRestrictionsInfiniteTree extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }

  fullConfig() {
    const infiniteTreeCfg = {
      infiniteTree: true,
      treeSelector: 'tree-container',
      nodeSelectorClass: 'largetree-node',
      decoratorNodeSelector: 'a.record-title',
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    if (document.getElementById(infiniteTreeCfg.treeSelector) === null) {
      infiniteTreeCfg.treeSelector = 'infinite-tree-container';
    }

    return {...cfg, ...infiniteTreeCfg};
  }
}
