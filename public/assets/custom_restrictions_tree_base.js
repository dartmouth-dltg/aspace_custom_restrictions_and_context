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
      rootNodeSelector: 'root-row',
      hasRestrictionsClass: 'custom-restriction-tree-node',
      noRestrictionsClass: 'no-custom-restriction-tree-node',
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
    return `<span class="label bg-danger badge">${data}</span>`
  }

  puiTreeWarning(data) {
    return `<span class="custom-restriction-visual-identifier" aria-hidden="true" title="${data}"></span><span class="custom-restrictions-visually-hidden">${data}</span>`
  }

  decorateTreeObject(data, el) {
    if (data.length > 0) {
      el.addClass(this.cfg.hasRestrictionsClass);
      if (this.cfg.isInfiniteRecord) {
        el.append(this.puiInfiniteRecordWarning(data));
      } else {
        el.prepend(this.puiTreeWarning(data));
      }
    }
    else {
      el.addClass(this.cfg.noRestrictionsClass);
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

  calcType(dataUri) {
    let type = '';
    if (dataUri.includes('::')) {
      type = `${dataUri.split('::')[1].split('_').slice(0,-1).join('_')}s`;
    } else {
      type = `${dataUri.split('/')[3]}`;
    }

    return type;
  }

  checkUri(dataUri) {
    if (dataUri.includes('::')) {
      const objectId = `${dataUri.split('::')[1].split('_').slice(-1)}`;
      dataUri = `${this.repoUri}/${type}/${objectId}`;
    }

    return dataUri;
  }

  getNodeData(el, mutate = true) {
    let node = null;

    if (mutate) {
      if (this.cfg.isInfiniteRecord || this.cfg.infiniteTree) {
        node = $(el);
      } else {
        node = $(el).find(`.${this.cfg.nodeSelectorClass}`).first();
      }
    } else {
      node = $(el);
    }
    if (node.hasClass(this.cfg.nodeSelectorClass) &&
      !node.hasClass(this.cfg.noRestrictionsClass) &&
      !node.hasClass(this.cfg.hasRestrictionsClass) &&
      !node.find(`a.${this.cfg.hasRestrictionsClass}`).length > 0 &&
      !node.find(`a.${this.cfg.noRestrictionsClass}`).length > 0
    ) {
      const initialDataUri = node.attr(this.cfg.uriSelector);
      const dataUri = this.checkUri(initialDataUri);
      const type = this.calcType(initialDataUri);
      this.fetchTreeObjectJson(dataUri, type, node);
    }
  }
  
  manipulateTree(mutationList) {
    const self = this;
    mutationList.forEach((el) => {
      if (el.type !== 'childList') {
        return;
      }
      if (el.addedNodes && el.addedNodes.length > 0) {
        $(el.addedNodes).each((idx, el) => {
          self.getNodeData(el)
        });
      }
    });
  }

  initialize() {
    const self = this;
    // add any restrictions on load
    $().ready(() => {
      let initialNodes = $(`#${self.cfg.treeSelector}`).find(`.${self.cfg.nodeSelectorClass}`);
      // all sorts of special for infinite tree
      // is there a better way to wait for the tree to load?
      if (this.cfg.infiniteTree) {
        setTimeout(() => {
          const rootNode = $(`#${self.cfg.treeSelector}`).find('.root-row');
          rootNode.addClass(self.cfg.nodeSelectorClass);
          self.getNodeData(rootNode, false);
          initialNodes = $(`#${self.cfg.treeSelector}`)
            .find(`.${self.cfg.nodeSelectorClass}`)
            .not(`.${self.cfg.rootNodeSelector}`)
            .not(`.${self.cfg.hasRestrictionsClass}`)
            .not(`.${self.cfg.noRestrictionsClass}`);
          initialNodes.each((idx, el) => {
            self.getNodeData(el, false);
          });
        }, 1000)
      } else {
        initialNodes.each((idx, el) => {
          self.getNodeData(el, false);
        });
      }
    });

    const manipTree = (mutationList, baseObserver) => {
      self.manipulateTree(mutationList);
    }
    const baseObserver = new MutationObserver(manipTree);
    baseObserver.observe(document.getElementById(this.cfg.treeSelector), this.mutationCfg.mutationConfig);
  }
}
