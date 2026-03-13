import HintsHandler from "./hints-handler.js";
import RequestHandler from "./request-handler.js";

function defaultNotify(item) {
  let data = item.notify;

  const types = {
    green: {
      className: "currentNotify--success",
      icon: "✓",
      text: "Sucesso",
    },
    red: {
      className: "currentNotify--danger",
      icon: "✕",
      text: "Negado",
    },
    yellow: {
      className: "currentNotify--warning",
      icon: "!",
      text: "Aviso",
    },
    blue: {
      className: "currentNotify--blue",
      icon: "i",
      text: "Info",
    },
  };

  if (!data) return;
  if (!types[data.index]) return;

  let time = data.time ? data.time : 3000;
  const type = types[data.index];

  var div = $(`
      <div class="currentNotify ${type.className} animate__animated animate__fadeInRight">
          <div class="notifyIcon">${type.icon}</div>
          <div class="notifyRightSide">
              <h1>${data.title ? data.title : type.text}</h1>
              <p>${data.message}</p>
          </div>
          <div class="notifyProgress">
              <div class="notifyProgress__bar" style="animation: notifyProgressShrink ${time}ms linear forwards;"></div>
          </div>
      </div>
      `)
    .appendTo(`.defaultNotifySide`)
    .hide()
    .show()
    .delay(time);

  setTimeout(() => {
    $(div).addClass(`animate__fadeOutRight`);
    setTimeout(() => {
      $(div).hide();
      $(div).remove();
    }, 1000);
  }, time);
}

let requests = new Map();

function handleRequest(data) {
  if (data.new) {
    const request = new RequestHandler(
      data.params.id,
      data.params.title,
      data.params.timer,
      data.params.description,
      data.params.acceptText,
      data.params.denyText
    );
    
    requests.set(request.getId(), request);

    request.show();
  } else if (data.response) {
    const request = requests.get(data.params.id);
    if (data.response === "accept") {
      request.onAccept();
    } else {
      request.onDeny();
    }
  }
}

const hints = new Map();

function handleHint(data) {
  const hintData = data.hint;
  const action = hintData.action;
  const id = hintData.id;

  if (action === "create") {
    const hint = new HintsHandler($("#hints"));
    hint.create(hintData.description, hintData.control, hintData.configs);

    if (hints.has(id)) {
      const oldHint = hints.get(id);
      oldHint.remove();
      hints.delete(id);
    }

    hints.set(id, hint);
  } else if (action === "remove") {
    const hint = hints.get(id);

    if (!hint) return;

    hint.remove();
    hints.delete(id);
  }
}

$(document).ready(function () {
  window.addEventListener("message", function (event) {
    let data = event.data;

    if (data.hint) {
      handleHint(data);
      return;
    }

    if (data.request) {
      handleRequest(data);
      return;
    }

    if (data.notify) {
      defaultNotify(data);
    }
  });
});

export async function sendClient(name, data, fn) {
	return $.post("http://dk_snippets/" + name, JSON.stringify(data), fn);
}