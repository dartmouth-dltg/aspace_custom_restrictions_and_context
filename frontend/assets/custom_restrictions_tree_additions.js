class CustomRestrictionsTree {

  constructor(repoId) {
    this.repoId = repoId;
    this.treeSelector = 'tree-container';
    this.infiniteTreeSelector = 'infinite-tree-container';
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
    if (
      !$(el).hasClass('no-custom-restriction-tree-node') &&
      !$(el).hasClass('custom-restriction-tree-node')
    ) {
      if (Object.keys(data).length > 0) {
        $(el).addClass('custom-restriction-tree-node').prepend(this.puiTreeWarning(data));
      }
      else {
        $(el).addClass('no-custom-restriction-tree-node');
      }
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
      console.log('Error fetching tree object json');
    });
  }

  prepareNodes(nodes) {
    const self = this;
    nodes.each((index, nodeEl) => {
      const node = $(nodeEl);
    if (
      !node.hasClass('no-custom-restriction-tree-node') &&
      !node.hasClass('custom-restriction-tree-node')
    ) {
      const href = node.attr('href');
      const uriParts = href.split("::").slice(-1).join('');
      const idAndType = uriParts.split("_");
      const id = idAndType.slice(-1).join('');
      const type = `${idAndType.slice(0, -1).join('_')}s`;

      self.fetchTreeObjectJson(id, type, node);
    }
  });
}
  
  observeTree(mutationList) {
    const self = this;

    mutationList.forEach((el) => {
      if (el.type !== 'childList') {
        return;
      }

      if (el.addedNodes && el.addedNodes.length > 0) {
        $(el.addedNodes).each((idx, el) => {

          const nodes = $(el).find(self.nodeSelector);
          if (nodes.length < 1) {
            return;
          }
          self.prepareNodes(nodes)
        });
      }
    });
  }

  initialize() {
    const self = this;
    const manipTree = (mutationList, observer) => {
      self.observeTree(mutationList);
    }
    const stdTree = document.getElementById(this.treeSelector);
    const infiniteTree = document.getElementById(this.infiniteTreeSelector);

    const observer = new MutationObserver(manipTree);
    if (stdTree !== null) {
      observer.observe(document.getElementById(this.treeSelector), this.mutationConfig);
    } else if (infiniteTree !== null) {
      observer.observe(document.getElementById(this.infiniteTreeSelector), this.mutationConfig);
    }
  }
}
