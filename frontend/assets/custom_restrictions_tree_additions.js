// Collects restriction lookups made in quick succession (e.g. a tree expanding) into
// a single GET request instead of one request per node.
class CustomRestrictionsBatcher {

  constructor(url, delay = 50, maxBatch = 50) {
    this.url = url;
    this.delay = delay;
    this.maxBatch = maxBatch;
    this.pending = new Map();
    this.timer = null;
  }

  request(uri, callback) {
    if (!this.pending.has(uri)) {
      this.pending.set(uri, []);
    }
    this.pending.get(uri).push(callback);

    if (this.timer === null) {
      this.timer = setTimeout(() => this.flush(), this.delay);
    }
  }

  flush() {
    this.timer = null;
    const uris = Array.from(this.pending.keys()).slice(0, this.maxBatch);
    if (uris.length === 0) {
      return;
    }

    const callbacks = uris.map((uri) => this.pending.get(uri));
    uris.forEach((uri) => this.pending.delete(uri));
    if (this.pending.size > 0) {
      this.timer = setTimeout(() => this.flush(), this.delay);
    }

    $.ajax({
      url: this.url,
      data: { uris: uris },
      method: 'get',
    }).done((data) => {
      uris.forEach((uri, idx) => callbacks[idx].forEach((cb) => cb((data || {})[uri])));
    }).fail(() => {
      console.log('Error fetching custom restrictions');
    });
  }
}

class CustomRestrictionsTree {

  constructor(repoId) {
    this.repoId = repoId;
    this.treeSelector = 'tree-container';
    this.nodeSelector = 'a.record-title';
    this.batcher = new CustomRestrictionsBatcher(AS.app_prefix('/plugins/aspace_custom_restrictions_and_context/restrictions'));
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
    if (data && data.length > 0) {
      $(el).addClass('custom-restriction-tree-node').prepend(this.puiTreeWarning(data));
    }
    else {
      $(el).addClass('no-custom-restriction-tree-node');
    }
  }

  fetchTreeObjectJson(id, recordType = 'archival_objects', el) {
    const uri = `/repositories/${this.repoId}/${recordType}/${id}`;
    this.batcher.request(uri, (data) => this.decorateTreeObject(data, el));
  }

  manipulateTree(mutationList) {
    const self = this;
    mutationList.forEach((el) => {
      if (el.type !== 'childList') {
        return;
      }
      if (el.addedNodes && el.addedNodes.length > 0) {
        $(el.addedNodes).each((idx, el) => {

          const node = $(el).find(self.nodeSelector);
          if (node.length < 1) {
            return;
          }

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
