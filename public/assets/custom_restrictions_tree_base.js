class CustomRestrictionsTreeBase {

  constructor(repoId) {
    this.repoId = repoId;
    this.treeSelector = 'tree-container';
    this.isInfiniteRecord = false;
    this.nodeSelectorClass = '';
    this.uriSelector = '';
    this.decoratorNodeSelector = '';
    this.mutationConfig = {
      attributes: false,
      childList: true,
      subtree: true,
    };
  }

  puiInfiniteRecordWarning(data) {
    return `<span class="label label-danger">${data}</span>`
  }

  puiTreeWarning(data) {
    return `<span class="custom-restriction-visual-identifier" aria-hidden="true" title="${data}"></span><span class="custom-restrictions-visually-hidden">${data}</span>`
  }

  decorateTreeObject(data, el) {
    if (Object.keys(data).length > 0) {
      $(el).addClass('custom-restriction-tree-node');
      if (this.isInfiniteRecord) {
        $(el).append(this.puiInfiniteRecordWarning(data));
      } else {
        $(el).prepend(this.puiTreeWarning(data));
      }
    }
    else {
      $(el).addClass('no-custom-restriction-tree-node');
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
      if (self.infiniteTree || self.isInfiniteRecord) {
        el = el.find(self.decoratorNodeSelector);
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
          if (self.isInfiniteRecord) {
            node = $(el);
          } else {
            node = $(el).find(`.${self.nodeSelectorClass}`);
          }
          if (node.hasClass(self.nodeSelectorClass) &&
            !node.hasClass('no-custom-restriction-tree-node') &&
            !node.hasClass('custom-restriction-tree-node')
          ) {
            const dataUri = node.attr(self.uriSelector);
            const type = `${dataUri.split('/')[3]}`;
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
    observer.observe(document.getElementById(this.treeSelector), this.mutationConfig);
  }
}
