#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdint.h>
#define NEW_MSG 6
#define NEW_BLOCK 2
#define STATUS_REG 4
#define DATA_REG 0
#define H0_REG 8
#define WORD 4



uint64_t create_msg_block();
void free_msg_block(uint64_t blocks);
uint32_t** msg_block;

int main(int argc, char const *argv[]) {

  int fd;
  int i;
  int j;
  int finish;
  uint64_t blocks;
  uint32_t status[1];
  uint32_t data[1];
  uint32_t hash[8];

  finish = 0;
  data[0] = 0;
  for (i=0; i<8; i++) {
    hash[i] = 0;
  }

  fd = open("/dev/sha256", O_RDWR); // generate a file descriptor to read and write to the device

  if (fd < 0) { // check if the device exist or not
    printf("fail to open /dev/sha256\n");
    return -1;
  }

  blocks = create_msg_block();
  status[0] = NEW_MSG;
  if ((pwrite(fd, status, WORD, STATUS_REG)) < 4) {
    printf("fail to write to status reg new_msg\n");
    exit (-1);
  }
  status[0] = NEW_BLOCK;
  //pread(fd, data, WORD, STATUS_REG);
  //printf ("status register %d\n", data[0]);

 //printf("block created\n");

  for (i=0; i<(blocks+1); i++) {
    for (j=0; j<16; j++) {
      if (pwrite(fd, &(msg_block[i][j]), WORD, DATA_REG) < 4) {
        printf("fail to write to data reg msg_block[%d][%d]\n", i,j);
        exit (-1);
      }
      //pread(fd, data, WORD, DATA_REG);
      //printf ("data register %d %d\n",j , data[0]);

    }
    if (i != blocks) { 
      if((pwrite(fd, status, WORD, STATUS_REG)) < 4) {
        printf("fail to write to status reg new_block\n");
        exit (-1);
      }
      //pread(fd, data, WORD, STATUS_REG);
      //printf ("status register %d %d\n",i, data[0]);
    }

  }

 //printf("waiting for hash valid\n");

  while (!finish) {
    if ((pread(fd, data, WORD, STATUS_REG)) < 4) {
      printf("fail to read from status reg\n");
      exit (-1);
    }
    //printf ("status register %d\n", data[0]);
    if ((data[0] & 0x1) == 1) {
      finish = 1;
    } else {
      finish = 0;
    }
  }


 //printf("hash valid detected\n");

  for (i=0; i<8; i++) {
    if ((pread(fd, &(hash[i]), WORD, ((WORD*i)+H0_REG))) < 4) {
      printf("fail to read from hash[%d]\n",i);
      exit (-1);
    }
  }

  printf("Hash of msg: ");
  for (i=0; i<8; i++) {
    printf("%08x", hash[i]);
  }
  printf("\n");


  free_msg_block(blocks);
  close(fd); // close the file descriptor related to the device
  return 0;
}

uint64_t create_msg_block () {

  char * buf;
  char c;
  int i = 0;
  int chunks = 0;
  int blocks;
  int read;
  uint64_t len;

  buf = (char *) malloc(64*sizeof(char));
  if (!buf) {
    printf("fail to allocate memory for the buffer\n");
    exit(-1);
  }

  printf("Enter the msg: ");
  while ((c = getchar()) != '\n') {
    buf[i] = c;
    i ++;
    if ((i % 64) == 63) { // reallocate the buffer every 64 chars
      chunks ++;
      i = chunks * 64 - 1;
      buf = (char *) realloc(buf, (chunks + 1) * 64 * sizeof(char));
      if (!buf) {
        printf("fail to reallocte memory for the buffer\n");
        exit(-1);
      }
    }
  }

  len = i;
  buf[i] = '\0';

  blocks = (len*8+64+1) / 512;
  msg_block = (uint32_t **) malloc((blocks+1)*sizeof(uint32_t*));
  if (!msg_block) {
    printf("fail to allocate memory for msg_block\n");
    exit(-1);
  }
  for (i=0; i<(blocks+1); i++) {
    msg_block[i] = (uint32_t *) malloc(16*sizeof(uint32_t));
    if (!msg_block[i]) {
      printf("fail to allocate memory for msg_block %d\n", i);
      exit(-1);
    }
  }

  uint32_t M = 0;
  uint32_t k = 0;
  uint32_t j = 0;
  uint32_t b = 0;
  uint8_t one;

  one = 128;
  read = 0;

  for (i=0; i<len; i+=4) {
    for (j=0; j<3; j++) {
      M = M ^ buf[(i+j)];
      M = M << 8;
      read ++;
    }
    M = M ^ buf[(i+j)];
    read ++;
    msg_block[b][k] = M;
    M = 0;
    k++;
    if (k == 16) {
      k = 0;
      b ++;
    }
  }

  M = 0;

  if (((len-56)%64) == 0) { // length of msg(56+64*k) need a new block only for '1' and padding
    M = ((M ^ one) << 24);
    msg_block[b][k] = M;
    msg_block[b][15] = 0;
    b ++;
    k = 0;
    M = 0;
  } else { // insert '1' and padding
    if ((len%4) != 0) { // the last M is not word alligned
      M = M ^ msg_block[b][k-1];
      M = (M | (one << ((4-(len%4)-1)*8)));
      msg_block[b][k-1] = M;
      M = 0;
    } else { // the last M is alligned
        M = 0;
        M = (M | (one << 24));
        msg_block[b][k] = M ;
        k++;
      }
    }

    M = 0;
    for (i=k; i<14; i++) { // insert padding
      msg_block[b][i] = M;
    }

    len = len*8;
    msg_block[b][14] = ((uint32_t*)&len)[1]; // insert the length of the buffer
    msg_block[b][15] = ((uint32_t*)&len)[0];

    /*
    for (b=0; b<(blocks+1); b++) {
      printf("block %d\n", b);
      for (j=0; j<16; j++) {
        printf("0x%08x\n", msg_block[b][j]);
      }
    }
    */

    free(buf);
    return blocks;
}

void free_msg_block(uint64_t blocks) {
  int i;
  for (i=0; i<(blocks+1); i++) {
    free(msg_block[i]);
  }
  free (msg_block);
}
