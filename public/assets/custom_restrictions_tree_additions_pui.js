class CustomRestrictionsTree extends CustomRestrictionsTreeBase {

  constructor(repoUri, appVersion = 4.1) {
    super(repoUri, appVersion);
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
