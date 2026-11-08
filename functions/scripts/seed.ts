#!/usr/bin/env npx ts-node

/**
 * Seed initial data for the LUNTI app
 * Run: npx ts-node scripts/seed.ts
 */

import * as admin from 'firebase-admin';

// Initialize with default credentials
admin.initializeApp();

const db = admin.firestore();

interface Product {
  name: string;
  description: string;
  type: 'product' | 'service';
  category: string;
  price: number;
  stock: number;
  engravingPrice: number;
  availableEngravings: string[];
  createdAt: Date;
}

const products: Product[] = [
  {
    name: 'Phone Speaker',
    description: 'A bamboo speaker housing that lets your phone's melody shine. Hand-carved from sustainable bamboo with natural grain variations.',
    type: 'product',
    category: 'electronics',
    price: 450,
    stock: 50,
    engravingPrice: 100,
    availableEngravings: ['Natural', 'Engraved'],
    createdAt: new Date(),
  },
  {
    name: 'Coaster',
    description: 'Set of two hand-carved bamboo coasters. Natural finish with a smooth surface that protects your surfaces from water rings.',
    type: 'product',
    category: 'accessories',
    price: 140,
    stock: 100,
    engravingPrice: 0,
    availableEngravings: [],
    createdAt: new Date(),
  },
  {
    name: 'Small Speaker',
    description: 'Compact bamboo speaker housing for smaller phones. Lightweight and portable with a natural aesthetic.',
    type: 'product',
    category: 'electronics',
    price: 150,
    stock: 30,
    engravingPrice: 100,
    availableEngravings: ['Natural', 'Engraved'],
    createdAt: new Date(),
  },
];

async function seed() {
  try {
    const batch = db.batch();
    
    for (const product of products) {
      const ref = db.collection('products').doc();
      batch.set(ref, {
        ...product,
        createdAt: admin.firestore.Timestamp.fromDate(product.createdAt),
      });
    }

    await batch.commit();
    console.log('✅ Products seeded successfully');
    
    // Verify
    const snapshot = await db.collection('products').get();
    console.log(`Found ${snapshot.size} products in collection`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding products:', error);
    process.exit(1);
  }
}

seed();