class CustomRestrictionsInfiniteTree extends CustomRestrictionsTreeBase {

  constructor(repoUri, appVersion = 4.0) {
    super(repoUri, appVersion);
  }

  fullConfig() {
    console.log(this.appVersion)
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
      nodeSelectorClass: 'node',
      rootNodeSelector: rootNodeSelector,
      decoratorNodeSelector: decoratorSelector,
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    if (document.getElementById(infiniteTreeCfg.treeSelector) === null) {
      infiniteTreeCfg.treeSelector = 'infinite-tree-container';
    }

    return {...cfg, ...infiniteTreeCfg};
  }
}
