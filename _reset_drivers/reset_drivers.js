/**
 * JOXMAKO — Driver Session Reset Script
 *
 * Resets all driver documents to a clean test state:
 *   - isActive         → false      (offline / not dispatched)
 *   - activeDeviceId   → ""         (session lock cleared)
 *   - ordercabRequestData  → deleted  (pending CAB request cleared)
 *   - orderRequestData     → []      (pending delivery request cleared)
 *   - orderParcelRequestData → deleted (pending parcel request cleared)
 *   - inProgressOrderID  → []        (in-progress rides cleared)
 *
 * PRESERVED (not touched):
 *   active, role, driverRole, vehicleDetails, documents,
 *   fcmToken, wallet, location, sectionIds, profilePictureURL,
 *   fullName, email, phoneNumber, bankName, accountNumber, etc.
 */

const admin = require('firebase-admin');
const serviceAccount = require('/Users/souafa/projects/Web/storage/app/firebase/credentials.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Firestore field names (verified from UserModel.dart) ──────────────────────
const FIELDS_TO_RESET = {
  isActive: false,
  activeDeviceId: admin.firestore.FieldValue.delete(),
  ordercabRequestData: admin.firestore.FieldValue.delete(),
  orderRequestData: [],
  orderParcelRequestData: admin.firestore.FieldValue.delete(),
  inProgressOrderID: [],
};

// ── Utility ───────────────────────────────────────────────────────────────────
function pad(n) { return String(n).padStart(3, ' '); }

async function resetDrivers() {
  console.log('');
  console.log('══════════════════════════════════════════════════════');
  console.log('  JOXMAKO — Driver Session Reset');
  console.log('══════════════════════════════════════════════════════');
  console.log('');

  // Fetch all documents where role == 'driver'
  const snapshot = await db.collection('users')
    .where('role', '==', 'driver')
    .get();

  if (snapshot.empty) {
    console.log('⚠  No driver documents found in Firestore.');
    return;
  }

  console.log(`Found ${snapshot.size} driver account(s). Starting reset...\n`);

  let resetCount = 0;
  let skippedCount = 0;
  let errorCount = 0;
  const results = [];

  // Firestore allows max 500 writes per batch
  const BATCH_SIZE = 400;
  let batches = [];
  let currentBatch = db.batch();
  let currentBatchSize = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const uid = doc.id;
    const name = [data.firstName, data.lastName].filter(Boolean).join(' ') || data.fullName || '(no name)';
    const email = data.email || '(no email)';

    // Check what actually needs to change
    const needsReset =
      data.isActive === true ||
      (data.activeDeviceId && data.activeDeviceId !== '') ||
      data.ordercabRequestData != null ||
      (data.orderRequestData && data.orderRequestData.length > 0) ||
      data.orderParcelRequestData != null ||
      (data.inProgressOrderID && data.inProgressOrderID.length > 0);

    if (!needsReset) {
      results.push({ uid, name, email, status: 'already_clean' });
      skippedCount++;
      continue;
    }

    // Log what we're resetting for this driver
    const dirty = [];
    if (data.isActive === true)        dirty.push('isActive=true');
    if (data.activeDeviceId)           dirty.push(`activeDeviceId="${data.activeDeviceId.substring(0,8)}..."`);
    if (data.ordercabRequestData)      dirty.push(`ordercabRequestData(id=${data.ordercabRequestData?.id ?? '?'})`);
    if (data.orderRequestData?.length) dirty.push(`orderRequestData[${data.orderRequestData.length}]`);
    if (data.orderParcelRequestData)   dirty.push('orderParcelRequestData');
    if (data.inProgressOrderID?.length) dirty.push(`inProgressOrderID[${data.inProgressOrderID.length}]`);

    currentBatch.update(doc.ref, FIELDS_TO_RESET);
    currentBatchSize++;
    results.push({ uid, name, email, status: 'reset', dirty });
    resetCount++;

    if (currentBatchSize >= BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      currentBatchSize = 0;
    }
  }

  if (currentBatchSize > 0) {
    batches.push(currentBatch);
  }

  // Commit all batches
  console.log(`Committing ${batches.length} Firestore batch(es)...\n`);
  for (let i = 0; i < batches.length; i++) {
    try {
      await batches[i].commit();
      console.log(`  ✓ Batch ${i + 1}/${batches.length} committed`);
    } catch (err) {
      errorCount++;
      console.error(`  ✗ Batch ${i + 1}/${batches.length} FAILED: ${err.message}`);
    }
  }

  // ── Summary ──────────────────────────────────────────────────────────────
  console.log('');
  console.log('──────────────────────────────────────────────────────');
  console.log('  DETAIL');
  console.log('──────────────────────────────────────────────────────');

  let i = 0;
  for (const r of results) {
    i++;
    if (r.status === 'reset') {
      console.log(`${pad(i)}. ✓ RESET   ${r.name} <${r.email}> [${r.uid}]`);
      console.log(`       Fields: ${r.dirty.join(', ')}`);
    } else {
      console.log(`${pad(i)}. — SKIP   ${r.name} <${r.email}> [${r.uid}] (already clean)`);
    }
  }

  console.log('');
  console.log('══════════════════════════════════════════════════════');
  console.log(`  RÉSULTAT`);
  console.log(`  Total drivers   : ${snapshot.size}`);
  console.log(`  Reset           : ${resetCount}`);
  console.log(`  Already clean   : ${skippedCount}`);
  console.log(`  Errors          : ${errorCount}`);
  console.log('══════════════════════════════════════════════════════');
  console.log('');

  if (errorCount === 0 && resetCount > 0) {
    console.log('✅ Reset complet. Tous les drivers sont hors ligne.');
    console.log('   Aucune session active, aucune demande en attente.');
  } else if (errorCount > 0) {
    console.log('⚠  Reset partiellement échoué. Vérifiez les erreurs ci-dessus.');
    process.exit(1);
  } else {
    console.log('ℹ  Rien à faire — tous les drivers étaient déjà dans un état propre.');
  }

  // Verify: re-read one driver to confirm
  if (resetCount > 0) {
    console.log('');
    console.log('── Vérification post-reset (premier driver réinitialisé)...');
    const resetDoc = results.find(r => r.status === 'reset');
    if (resetDoc) {
      const verify = await db.collection('users').doc(resetDoc.uid).get();
      const vd = verify.data();
      console.log(`   ${resetDoc.name} [${resetDoc.uid}]`);
      console.log(`   isActive             = ${vd.isActive ?? '(not set)'}`);
      console.log(`   activeDeviceId       = ${vd.activeDeviceId ?? '(deleted/empty)'}`);
      console.log(`   ordercabRequestData  = ${vd.ordercabRequestData != null ? 'STILL PRESENT ⚠' : '(deleted) ✓'}`);
      console.log(`   orderRequestData     = ${JSON.stringify(vd.orderRequestData ?? [])}`);
      console.log(`   inProgressOrderID    = ${JSON.stringify(vd.inProgressOrderID ?? [])}`);
    }
  }

  console.log('');
}

resetDrivers().catch(err => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
