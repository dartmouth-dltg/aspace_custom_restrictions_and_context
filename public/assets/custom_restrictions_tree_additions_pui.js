class CustomRestrictionsTree extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }

  fullConfig() {
    const treeCfg = {
      decoratorNodeSelector: 'a.record-title',
      nodeSelectorClass: 'record-title',
      uriSelector: 'href',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...treeCfg};
  }
}
