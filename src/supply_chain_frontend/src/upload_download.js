import { supply_chain_backend } from "../../declarations/supply_chain_backend";

let file;

const uploadChunk = async ({batch_name, chunk}) => supply_chain_backend.create_chunk({
  batch_name,
  content: [...new Uint8Array(await chunk.arrayBuffer())]
})

const upload = async () => {

  if (!file) {
    alert('No file selected');
    return;
  }

  console.log('start upload');

  const batch_name = file.name;
  const promises = [];
  const chunkSize = 1500000;

  for (let start = 0; start < file.size; start += chunkSize) {
    const chunk = file.slice(start, start + chunkSize);

    promises.push(uploadChunk({
      batch_name,
      chunk
    }));
  }

  const chunkIds = await Promise.all(promises);

  console.log(chunkIds);

  await supply_chain_backend.commit_batch({
    batch_name,
    chunk_ids: chunkIds.map(({chunk_id}) => chunk_id),
    content_type: file.type
  })

  console.log('uploaded');

  loadImage(batch_name);
}

const loadImage = (batch_name) => {

  if (!batch_name) {
    return;
  }

  const newImage = document.createElement('img');
  newImage.src = `http://127.0.0.1:4943/assets/${batch_name}?canisterId=r7inp-6aaaa-aaaaa-aaabq-cai`;

  const img = document.querySelector('section:last-of-type img');
  img?.parentElement.removeChild(img);

  const section = document.querySelector('section:last-of-type');
  section?.appendChild(newImage);
}

const input = document.querySelector('input');
input?.addEventListener('change', ($event) => {
  file = $event.target.files?.[0];
  console.log("here");
});

const btnUpload = document.querySelector('button.upload');
btnUpload?.addEventListener('click', upload);