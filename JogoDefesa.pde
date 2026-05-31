import processing.sound.*; 

// --- IMAGENS E SONS ---
PImage bgImg, baseImg, canoImg, heliImg, pqdImg, projetilImg;
SoundFile somExplosao; 
SoundFile somTiro;
SoundFile somGrito;

// --- VARIÁVEIS DA ANIMAÇÃO DO LOADING ---
PImage spriteSheetRun;
int numFrames = 11; // Os 11 bonecos da animação
PImage[] runAnim;

// --- LISTAS PARA OS OBJETOS NA TELA ---
ArrayList<Bullet> bullets;
ArrayList<Helicopter> helicopters;
ArrayList<Paratrooper> pqds;
ArrayList<Particle> particles;

// O jogador (canhão)
Player player;

// Variáveis do jogo
int score = 0;
int vidas = 3; 
int heliSpawnTimer = 0;
int gameState = 0; // 0: Loading, 3: Tela Inicial, 1: Jogando, 2: Game Over
int loadStartTime;
int lastMissileTime = -3000; // Tempo do míssil

void setup() {
  size(800, 600); 
  imageMode(CENTER); 
  
  bullets = new ArrayList<Bullet>();
  helicopters = new ArrayList<Helicopter>();
  pqds = new ArrayList<Paratrooper>();
  particles = new ArrayList<Particle>();
  
  // --- CARREGA AS IMAGENS ---
  bgImg = loadImage("fundo.jpg");
  if (bgImg != null) bgImg.resize(width, height);
  
  baseImg = loadImage("base.png");
  if (baseImg != null) baseImg.resize(80, 80);
  
  canoImg = loadImage("cano.png");
  if (canoImg != null) canoImg.resize(80, 80);
  
  heliImg = loadImage("heli.png");
  if (heliImg != null) heliImg.resize(140, 60);
  
  pqdImg = loadImage("paraquedista.png");
  if (pqdImg != null) pqdImg.resize(45, 65);
  
  projetilImg = loadImage("tiro.png"); 
  if (projetilImg != null) projetilImg.resize(15, 35); 
  
  // --- CARREGA E FATIA A ANIMAÇÃO DO BONECO ---
  spriteSheetRun = loadImage("boneco_run.png");
  if (spriteSheetRun != null) {
    runAnim = new PImage[numFrames];
    int frameW = spriteSheetRun.width / numFrames; 
    int frameH = spriteSheetRun.height;
    
    for (int i = 0; i < numFrames; i++) {
      runAnim[i] = spriteSheetRun.get(i * frameW, 0, frameW, frameH);
    }
  } else {
    println("Erro: Não encontrou o boneco_run.png na pasta data.");
  }
  
  // --- CARREGA OS SONS E AJUSTA O VOLUME ---
  try {
    somExplosao = new SoundFile(this, "explosion.mp3");
    somExplosao.amp(0.6); 
    
    somTiro = new SoundFile(this, "tiro.mp3");
    somTiro.amp(0.4); 
    
    somGrito = new SoundFile(this, "grito_pqd.mp3");
    somGrito.amp(0.05); // Volume configurado apenas no setup (5%)
  } catch (Exception e) {
    println("Erro ao carregar os sons. Verifique os nomes na pasta data.");
  }
  
  player = new Player();
  loadStartTime = millis(); 
}

void draw() {
  // --- TELA DE LOADING (gameState 0) ---
  if (gameState == 0) {
    background(0);
    
    // Desenha o boneco correndo
    if (runAnim != null && runAnim[0] != null) {
      int frameAtual = (frameCount / 5) % numFrames; 
      
      pushMatrix();
      translate(width/2, height/2 - 40);
      scale(2.5); 
      image(runAnim[frameAtual], 0, 0);
      popMatrix();
    }
    
    fill(255);
    textSize(28);
    textAlign(CENTER, CENTER);
    text("Escondendo os bugs do professor... Aguarde.", width/2, height/2 + 80);
    
    if (millis() - loadStartTime > 2500) {
      gameState = 3;
    }
    return; 
  }

  // --- TELA DE INÍCIO / HISTÓRIA E CRÉDITOS (gameState 3) ---
  if (gameState == 3) {
    if (bgImg != null) {
      imageMode(CORNER);
      tint(255, 130, 130); 
      image(bgImg, 0, 0);
      noTint();
      imageMode(CENTER);
    } else {
      background(40, 15, 15); 
    }
    
    fill(0, 205);
    rectMode(CORNER);
    rect(40, 40, width - 80, height - 80, 15);
    
    fill(255, 80, 80);
    textAlign(CENTER, TOP);
    textSize(38);
    text("DEFESA DA CIDADE", width/2, 60);
    
    fill(210);
    textSize(17);
    String historia = "Após um ataque surpresa de uma nação inimiga,\num bravo operador de torreta tenta defender os céus\nde sua cidade dos ataques aéreos sem nenhum apoio.";
    text(historia, width/2, 120);
    
    fill(255);
    textSize(20);
    text("COMO JOGAR:", width/2, 210);
    
    textSize(15);
    fill(180, 240, 180);
    text("• MOUSE: Mira a torreta antiaérea", width/2, 245);
    text("• BOTÃO ESQUERDO: Disparo rápido da metralhadora", width/2, 270);
    text("• BOTÃO DIREITO: Míssil pesado de área (Recarga de 3s)", width/2, 295);
    
    fill(255);
    textSize(19);
    text("DESENVOLVIDO POR (777 STUDIOS):", width/2, 345);
    
    textSize(14);
    fill(200);
    textAlign(LEFT, TOP);
    text("• Assuero Eduardo C. Guimarães\n• Giovanni Saverio S. Rocha\n• Guilherme Soares de A. Rocha", width/2 - 260, 380);
    
    text("• Maria Clara P. de Sousa\n• Matheus Rodrigues de Souza\n• Thaysa Maria C. Santiago", width/2 + 30, 380);
    
    textAlign(CENTER, TOP);
    textSize(15);
    fill(255, 130, 130);
    text("Não deixe os paraquedistas tocarem no chão!", width/2, 455);
    
    fill(255, 255, 0);
    textSize(19);
    if (millis() % 1000 < 500) {
      text("CLIQUE NA TELA PARA INICIAR A DEFESA", width/2, 500);
    }
    
    return; 
  }
  
  // --- TELA DE GAME OVER (gameState 2) ---
  if (gameState == 2) {
    background(50, 0, 0); 
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(50);
    text("GAME OVER", width/2, height/2 - 40);
    textSize(24);
    text("Pontuação Final: " + score, width/2, height/2 + 20);
    textSize(18);
    text("Clique no mouse para reiniciar", width/2, height/2 + 70);
    return; 
  }
  
  // --- JOGO RODANDO (gameState 1) ---
  if (bgImg != null) {
    imageMode(CORNER);
    image(bgImg, 0, 0);
    imageMode(CENTER);
  } else {
    background(50);
  }
  
  int currentSpawnRate = (int) max(40, 120 - (score / 10));
  
  heliSpawnTimer++;
  if (heliSpawnTimer > currentSpawnRate) { 
    helicopters.add(new Helicopter()); 
    heliSpawnTimer = 0;
  }
  
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.x < 0 || b.x > width || b.y < 0) bullets.remove(i);
  }
  
  for (int i = helicopters.size() - 1; i >= 0; i--) {
    Helicopter h = helicopters.get(i);
    h.update();
    h.display();
    if (h.x < -200 || h.x > width + 200) helicopters.remove(i);
  }
  
  for (int i = pqds.size() - 1; i >= 0; i--) {
    Paratrooper p = pqds.get(i);
    p.update();
    p.display();
    
    if (p.y > height) {
      pqds.remove(i); 
      vidas--; 
      if (vidas <= 0) {
        gameState = 2; 
      }
    }
  }
  
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle part = particles.get(i);
    part.update();
    part.display();
    if (part.timer <= 0) particles.remove(i); 
  }
  
  // --- COLISÕES ---
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    boolean hit = false;
    
    // Tiro x Helicóptero
    for (int j = helicopters.size() - 1; j >= 0; j--) {
      Helicopter h = helicopters.get(j);
      
      if (dist(b.x, b.y, h.x, h.y) < 50) { 
        if (b.isMissile) h.hp -= 3; 
        else { h.hp -= 1; h.hitTimer = 5; }
        
        if (h.hp <= 0) {
          if (somExplosao != null) somExplosao.play(); 
          for (int k = 0; k < 20; k++) {
            particles.add(new Particle(h.x, h.y, color(255, random(100, 200), 0))); 
          }
          helicopters.remove(j); 
          score += 50; 
        }
        hit = true;
        break; 
      }
    }
    
    if (hit) {
      bullets.remove(i);
      continue; 
    }
    
    // Tiro x Paraquedista
    for (int j = pqds.size() - 1; j >= 0; j--) {
      Paratrooper p = pqds.get(j);
      if (dist(b.x, b.y, p.x, p.y) < 25) { 
        
        // --- TOCA O GRITO AQUI (De forma simples) ---
        if (somGrito != null) somGrito.play();
        
        for (int k = 0; k < 15; k++) {
          particles.add(new Particle(p.x, p.y, color(139, 0, 0)));
        }
        pqds.remove(j); 
        hit = true;
        score += 10; 
        break; 
      }
    }
    
    if (hit) bullets.remove(i);
  }
  
  player.display();
  
  fill(255);
  textSize(24);
  textAlign(LEFT, TOP);
  text("Pontos: " + score, 10, 10);
  
  textAlign(RIGHT, TOP);
  fill(vidas == 1 ? color(255, 0, 0) : color(255)); 
  text("Vidas: " + vidas, width - 10, 10);
}

void mousePressed() {
  if (gameState == 3) {
    gameState = 1;
    lastMissileTime = millis() - 3000; 
    return;
  }

  if (gameState == 1) {
    float angle = atan2(mouseY - player.y, mouseX - player.x);
    
    // Ajustes do canhão duplo da nova torreta
    float distPonta = 65; 
    float distLado = 12; 
    float anguloLateral = angle + HALF_PI;
    float ladoAleatorio = random(1) > 0.5 ? distLado : -distLado;
    
    float pontaCanhaoX = player.x + (cos(angle) * distPonta) + (cos(anguloLateral) * ladoAleatorio);
    float pontaCanhaoY = player.y + (sin(angle) * distPonta) + (sin(anguloLateral) * ladoAleatorio);
    
    if (mouseButton == LEFT) {
      bullets.add(new Bullet(pontaCanhaoX, pontaCanhaoY, mouseX, mouseY, false)); 
      if (somTiro != null) somTiro.play();
      
    } else if (mouseButton == RIGHT) {
      if (millis() - lastMissileTime >= 3000) { 
        float missilX = player.x + (cos(angle) * distPonta);
        float missilY = player.y + (sin(angle) * distPonta);
        
        bullets.add(new Bullet(missilX, missilY, mouseX, mouseY, true)); 
        if (somExplosao != null) somExplosao.play();
        lastMissileTime = millis(); 
      }
    }
  } 
  else if (gameState == 2) {
    score = 0;
    vidas = 3;
    lastMissileTime = millis() - 3000;
    bullets.clear();
    helicopters.clear();
    pqds.clear();
    particles.clear();
    gameState = 1;
  }
}

// ================= CLASSES =================
class Player {
  float x, y;
  Player() {
    x = width / 2;
    y = height - 40; 
  }
  void display() {
    if (baseImg != null) image(baseImg, x, y + 15); 
    
    float angle = atan2(mouseY - y, mouseX - x); 
    pushMatrix();
    
    translate(x, y - 8); 
    
    // Compensa os 90 graus da imagem virada para cima
    rotate(angle + HALF_PI); 
    
    // Cola o cano na base
    if (canoImg != null) image(canoImg, 0, -15); 
    
    popMatrix();
  }
}

class Bullet {
  float x, y, dx, dy;
  float speed = 15;
  float renderAngle; 
  boolean isMissile; 
  
  Bullet(float startX, float startY, float targetX, float targetY, boolean isMissileInput) {
    x = startX;
    y = startY;
    isMissile = isMissileInput;
    
    float angle = atan2(targetY - startY, targetX - startX);
    speed = isMissile ? 12 : 20; 
    dx = cos(angle) * speed;
    dy = sin(angle) * speed;
    renderAngle = angle + HALF_PI; 
  }
  void update() { x += dx; y += dy; }
  void display() {
    if (isMissile && projetilImg != null) {
      pushMatrix();
      translate(x, y);
      rotate(renderAngle); 
      image(projetilImg, 0, 0);
      popMatrix();
    } else {
      fill(255, 255, 0);
      noStroke();
      ellipse(x, y, 8, 8);
    }
  }
}

class Helicopter {
  float x, y, speed;
  int direction;
  int spawnTimer = 0;
  int hp = 3; 
  int hitTimer = 0; 
  
  Helicopter() {
    y = random(30, 150);
    speed = random(3, 5);
    direction = random(1) > 0.5 ? 1 : -1; 
    if (direction == 1) x = -100; else { x = width + 100; speed *= -1; }
  }
  void update() {
    x += speed;
    spawnTimer++;
    
    if (spawnTimer > 60 && random(1) < 0.02 && x > 50 && x < width - 50) {
      pqds.add(new Paratrooper(x, y + 30)); 
      spawnTimer = 0;
    }
    if (hitTimer > 0) hitTimer--;
  }
  void display() {
    if (heliImg != null) {
      pushMatrix();
      translate(x, y);
      if (direction == 1) scale(-1, 1); 
      if (hitTimer > 0) tint(255, 100, 100); 
      image(heliImg, 0, 0);
      noTint(); 
      popMatrix();
    }
  }
}

class Paratrooper {
  float x, y, speedY;
  Paratrooper(float startX, float startY) {
    x = startX; y = startY;
    speedY = random(1.5, 2.5);
  }
  void update() { y += speedY; }
  void display() { if (pqdImg != null) image(pqdImg, x, y); }
}

class Particle {
  float x, y, vx, vy, timer, size;
  color c;
  Particle(float startX, float startY, color particleColor) {
    x = startX; y = startY;
    vx = random(-4, 4); 
    vy = random(-5, 1); 
    timer = random(20, 40); 
    size = random(3, 6);
    c = particleColor; 
  }
  void update() {
    x += vx; y += vy;
    vy += 0.3; // Gravidade
    timer--;
  }
  void display() {
    fill(c); noStroke();
    rectMode(CENTER);
    rect(x, y, size, size);
    rectMode(CORNER);
  }
}
