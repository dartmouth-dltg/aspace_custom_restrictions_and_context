class CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    this.repoUri = repoUri;
    this.cfg = this.fullConfig();
    this.mutationCfg = this.mutationConfig();
  }

  baseConfig() {
   return {
      infiniteTree: false,
      isInfiniteRecord: false,
      isInfiniteScroll: false,
      treeSelector: 'tree-container',
      nodeSelectorClass: '',
      uriSelector: '',
      decoratorNodeSelector: '',
    };
  }

  fullConfig() {
    // must implement in child class
    console.log('Implement fullConfig() method in child class');
  }

  mutationConfig() {
    return {
      mutationConfig: {
        attributes: false,
        childList: true,
        subtree: true,
      },
    };
  }

  config_overrides() {
    // must be implemented in child class
  }

  puiInfiniteRecordWarning(data) {
    return `<span class="label label-danger">${data}</span>`
  }

  puiTreeWarning(data) {
    return `<span class="custom-restriction-visual-identifier" aria-hidden="true" title="${data}"></span><span class="custom-restrictions-visually-hidden">${data}</span>`
  }

  decorateTreeObject(data, el) {
    if (data.length > 0) {
      el.addClass('custom-restriction-tree-node');
      if (this.cfg.isInfiniteRecord) {
        el.append(this.puiInfiniteRecordWarning(data));
      } else {
        el.prepend(this.puiTreeWarning(data));
      }
    }
    else {
      el.addClass('no-custom-restriction-tree-node');
    }
  }

  fetchTreeObjectJson(dataUri, recordType = 'archival_objects', el) {
    const self = this;

    $.ajax({
      url: '/aspace_custom_restrictions_and_context/pui_restrictions',
      data: {
        uri: dataUri,
        type: recordType,
      },
      method: 'post',
    }).done((data) => {
      if (self.cfg.infiniteTree || self.cfg.isInfiniteRecord) {
        el = el.find(self.cfg.decoratorNodeSelector);
      }
      self.decorateTreeObject(data, el);
    }).fail(() => {
      console.log('Error fetching object json');
    });
  }
  
  manipulateTree(mutationList) {
    const self = this;
    let nodes = null;
    mutationList.forEach((el) => {
      if (el.type !== 'childList') {
        return;
      }
      if (el.addedNodes && el.addedNodes.length > 0) {
        $(el.addedNodes).each((idx, el) => {
          let node = null;
          if (self.cfg.isInfiniteRecord) {
            node = $(el);
          } else {
            node = $(el).find(`.${self.cfg.nodeSelectorClass}`);
          }
          if (node.hasClass(self.cfg.nodeSelectorClass) &&
            !node.hasClass('no-custom-restriction-tree-node') &&
            !node.hasClass('custom-restriction-tree-node')
          ) {
            let dataUri = node.attr(self.cfg.uriSelector);
            let type = '';
            if (dataUri.includes('::')) {
              type = `${dataUri.split('::')[1].split('_').slice(0,-1).join('_')}s`;
              const objectId = `${dataUri.split('::')[1].split('_').slice(-1)}`;
              dataUri = `${self.repoUri}/${type}/${objectId}`;
            } else {
              type = `${dataUri.split('/')[3]}`;
            }
            self.fetchTreeObjectJson(dataUri, type, node);
          }
        });
      }
    });
  }

  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.manipulateTree(mutationList);
    }
    const observer = new MutationObserver(manipTree);
    observer.observe(document.getElementById(this.cfg.treeSelector), this.mutationCfg.mutationConfig);
  }
}
