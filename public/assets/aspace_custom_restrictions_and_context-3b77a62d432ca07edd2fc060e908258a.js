class CustomRestrictionsPui {
  constructor(searchData) {
    this.searchData = searchData;
    this.searchResultsSelector = '.search-results';
    this.objectHeadingSelector = '#content h1';
  }

  puiRestrictionTemplate(data) {
    return `<span class="aspace-custom-restrictions label label-danger">${data}</span>`;
  }

  decoratePuiSearch(target, dataUri) {
    const self = this;
    const parsedData = JSON.parse(this.searchData);

    // archival objects have an extra fragment
    if (dataUri.includes('archival_object')) {
      dataUri += '#pui'
    }
    if (parsedData[dataUri] && parsedData[dataUri]['custom_restrictions'].length > 0) {
      target.after(self.puiRestrictionTemplate(parsedData[dataUri]['custom_restrictions']))
    }
  }
  
  setupDecoratePuiSearch() {
    const self = this;
    $(this.searchResultsSelector).find('.recordrow').each(function iteratePuiResults() {
      const target = $(this).find('.record-title');
      const dataUri = $(this).attr('data-uri');
      self.decoratePuiSearch(target, dataUri);
    });
  }

  objectRestrictionDisplay(restriction) {
    const self = this;
    const target = $(self.objectHeadingSelector);
    target.append(self.puiRestrictionTemplate(restriction))
  }
}
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
    return {...cfg, ...infiniteTreeCfg};
  }
}
class CustomRestrictionsInfiniteRecords extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }

  fullConfig() {
    const infiniteRecordCfg = {
      treeSelector: 'infinite-records-container',
      infiniteTree: true,
      isInfiniteRecord: true,
      isInfiniteScroll: false,
      nodeSelectorClass: 'infinite-record-record',
      decoratorNodeSelector: '.infinite-item h3',
      uriSelector: 'data-uri',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...infiniteRecordCfg};
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.manipulateTree(mutationList);
    }
    const observer = new MutationObserver(manipTree);
    observer.observe(document.getElementsByClassName(this.cfg.treeSelector)[0], this.mutationCfg.mutationConfig);
  }
}
class CustomRestrictionsInfiniteScroll extends CustomRestrictionsTreeBase {

  constructor(repoUri, tree) {
    super(repoUri, tree);
  }
  
  fullConfig() {
    const infiniteScrollCfg = {
      isInfiniteScroll: true,
      treeSelector: 'infinite-record-wrapper',
      nodeSelectorClass: 'record-title',
      decoratorNodeSelector: 'a.recordTitle',
      uriSelector: 'href',
    };

    const cfg = this.baseConfig();
    return {...cfg, ...infiniteScrollCfg};
  }

  // infinite record panes do not have an id to find, so we need to go with a class name
  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.manipulateTree(mutationList);
    }
    const observer = new MutationObserver(manipTree);
    observer.observe(document.getElementsByClassName(this.cfg.treeSelector)[0], this.mutationCfg.mutationConfig);
  }
}
