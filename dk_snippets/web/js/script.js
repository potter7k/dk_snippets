import RequestHandler from "./request-handler.js";

function defaultNotify(item) {
  let data = item.notify;
  let images = {
    green: {
      image: "./assets/images/success.png",
      text: "Sucesso",
    },
    red: {
      image: "./assets/images/danger.png",
      text: "Negado",
    },
    yellow: {
      image: "./assets/images/warning.png",
      text: "Aviso",
    },
  };

  if (!data) return;
  if (!images[data.index]) return;
  let time = data.time ? data.time : 3000;
  var div = $(`
      <div class="currentNotify animate__animated animate__fadeInRight">
          <div class="notifyLeftSide">
              <img src="${images[data.index].image}" alt="">
          </div>
          <div class="notifyRightSide">
              <h1>${data.title ? data.title : images[data.index].text}</h1>
              <p>${data.message}</p>
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
      data.params.description
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

$(document).ready(function () {
  window.addEventListener("message", function (event) {
    let data = event.data;

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