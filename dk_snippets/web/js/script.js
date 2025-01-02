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

$(document).ready(function () {
  window.addEventListener("message", function (event) {
    let item = event.data;

    if (item.notify) {
      defaultNotify(item);
    }
  });
});
