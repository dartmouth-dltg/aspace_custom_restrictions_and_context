class CustomRestrictionsTree {

  constructor(tree) {
    const self = this;
    this.tree = tree;
    this.treeSelector = '#tree-container a.record-title';
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
      self.decorateTreeObject(data, el);
    }).fail(() => {
      console.log('Error fetching object json');
    });
  }
  
  manipulateTree() {
    const self = this;

    $(this.treeSelector).each((idx, el) => {
      const node = $(el);
      if (!node.hasClass('no-custom-restriction-tree-node') && !node.hasClass('custom-restriction-tree-node')) {
        const href = node.attr('href');
        const type = `${href.split('/')[3]}`;
        self.fetchTreeObjectJson(href, type, el);
      }
    })
  }

  initialize() {
    const self = this;

    this.tree.addPopulateWaypointHook(() => {
      self.manipulateTree()
    });

    $('#tree-container').on('click', '.record-title', () => {
      self.manipulateTree();
    });
  }
}
