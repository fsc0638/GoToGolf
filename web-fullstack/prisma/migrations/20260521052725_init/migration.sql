-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "name" TEXT,
    "passwordHash" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Round" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "title" TEXT NOT NULL,
    "courseName" TEXT NOT NULL,
    "holeCount" INTEGER NOT NULL DEFAULT 18,
    "currentHole" INTEGER NOT NULL DEFAULT 1,
    "totalGross" INTEGER NOT NULL DEFAULT 0,
    "totalPar" INTEGER NOT NULL DEFAULT 72,
    "status" TEXT NOT NULL DEFAULT 'IN_PROGRESS',
    "userId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Round_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "HoleScore" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "roundId" TEXT NOT NULL,
    "hole" INTEGER NOT NULL,
    "par" INTEGER NOT NULL,
    "gross" INTEGER NOT NULL,
    CONSTRAINT "HoleScore_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "Round" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "HoleScore_roundId_hole_key" ON "HoleScore"("roundId", "hole");
