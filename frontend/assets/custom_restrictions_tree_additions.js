class CustomRestrictionsTree {

  constructor(repoId) {
    this.repoId = repoId;
    this.treeSelector = 'tree-container';
    this.nodeSelector = 'a.record-title';
    this.mutationConfig = {
      attributes: false,
      childList: true,
      subtree: true,
    };
  }

  puiTreeWarning(data) {
    return `<span class="custom-restriction-visual-identifier" aria-hidden="true" title="${data}"></span><span class="custom-restrictions-visually-hidden">${data}</span>`
  }

  decorateTreeObject(data, el) {
    if (Object.keys(data).length > 0) {
      $(el).addClass('custom-restriction-tree-node').prepend(this.puiTreeWarning(data));
    }
    else {
      $(el).addClass('no-custom-restriction-tree-node');
    }
  }

  fetchTreeObjectJson(id, recordType = 'archival_objects', el) {
    const self = this;

    $.ajax({
      url: '/plugins/aspace_custom_restrictions_and_context/mini_tree',
      data: {
        id: id,
        repo_id: self.repoId,
        type: recordType,
        restrictions_only: true,
      },
      method: 'post',
    }).done((data) => {
      self.decorateTreeObject(data, el);
    }).fail(() => {
      console.log('Error fetching object json');
    });
  }
  
  manipulateTree(mutationList) {
    const self = this;
    mutationList.forEach((el) => {
      if (el.type !== 'childList') {
        return;
      }
      if (el.addedNodes && el.addedNodes.length > 0) {
        $(el.addedNodes[0]).find(self.nodeSelector).each((idx, el) => {
          const node = $(el);
          if (!node.hasClass('no-custom-restriction-tree-node') && !node.hasClass('custom-restriction-tree-node')) {
            const href = node.attr('href');
            const uriParts = href.split("::").slice(-1).join('');
            const idAndType = uriParts.split("_");
            const id = idAndType.slice(-1).join('');
            const type = `${idAndType.slice(0, -1).join('_')}s`;

            self.fetchTreeObjectJson(id, type, el);
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
